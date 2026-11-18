#pragma once
#include <juce_core/juce_core.h>
#include <juce_cryptography/juce_cryptography.h>
#include <atomic>
#include <cmath>
#include <cstdint>

class LicenseManager
{
public:
    static constexpr int     kTrialDurationDays    = 7;
    static constexpr int64_t kTrialDurationSeconds = static_cast<int64_t>(kTrialDurationDays) * 24 * 60 * 60;
    static constexpr const char* kStoreUrl         = "https://sfalabs.digital";

    static LicenseManager& getInstance()
    {
        static LicenseManager instance;
        return instance;
    }

    bool isLicensed() const { return licenseValid.load(std::memory_order_relaxed); }

    juce::String getLicensedEmail() const { return licensedEmail; }

    void checkStoredLicense()
    {
        ensureTrialInitialized();

        auto licenseFile = getLicenseFile();
        if (licenseFile.existsAsFile())
        {
            auto content = licenseFile.loadFileAsString();
            auto tokens = juce::StringArray::fromTokens(content, "|", "");
            if (tokens.size() == 2)
            {
                const auto email = tokens[0].trim();
                const auto key   = tokens[1].trim();
                if (verifyKey(email, key))
                {
                    licensedEmail = email;
                    licenseValid.store(true, std::memory_order_relaxed);
                    return;
                }
            }
        }
        licenseValid.store(false, std::memory_order_relaxed);
    }

    bool activateLicense(const juce::String& email, const juce::String& serialKey)
    {
        if (verifyKey(email, serialKey))
        {
            auto licenseFile = getLicenseFile();
            licenseFile.getParentDirectory().createDirectory();
            licenseFile.replaceWithText(email.trim() + "|" + serialKey.trim().toUpperCase());
            licensedEmail = email.trim();
            licenseValid.store(true, std::memory_order_relaxed);
            return true;
        }
        return false;
    }

    bool isTrialExpiredNow() const
    {
        if (isLicensed())
            return false;

        if (trialTampered.load(std::memory_order_relaxed))
            return true;

        const int64_t startSec = trialStartEpochSeconds.load(std::memory_order_relaxed);
        if (startSec <= 0)
            return false;

        const int64_t nowSec = juce::Time::getCurrentTime().toMilliseconds() / 1000;

        // Guard against clock rollback by more than 24 hours
        if (nowSec < startSec - 86400)
            return true;

        return (nowSec - startSec) >= kTrialDurationSeconds;
    }

    int64_t getTrialSecondsRemaining() const
    {
        if (isLicensed())
            return kTrialDurationSeconds;

        if (trialTampered.load(std::memory_order_relaxed))
            return 0;

        const int64_t startSec = trialStartEpochSeconds.load(std::memory_order_relaxed);
        if (startSec <= 0)
            return kTrialDurationSeconds;

        const int64_t nowSec = juce::Time::getCurrentTime().toMilliseconds() / 1000;
        if (nowSec < startSec - 86400)
            return 0;

        const int64_t elapsed = juce::jmax<int64_t>(0, nowSec - startSec);
        return juce::jmax<int64_t>(0, kTrialDurationSeconds - elapsed);
    }

    int getTrialDaysRemaining() const
    {
        const int64_t remSec = getTrialSecondsRemaining();
        if (remSec <= 0)
            return 0;

        return static_cast<int>(std::ceil(static_cast<double>(remSec) / 86400.0));
    }

    juce::File getLicenseFile() const
    {
        auto dir = juce::File::getSpecialLocation(juce::File::userApplicationDataDirectory)
                       .getChildFile("SignalForge");
        auto viennaLic = dir.getChildFile("ClassicVienna290.lic");
        auto legacyLic = dir.getChildFile("Bosendorfer290.lic");
        if (!viennaLic.existsAsFile() && legacyLic.existsAsFile())
            return legacyLic;
        return viennaLic;
    }

    juce::File getTrialFile() const
    {
        return juce::File::getSpecialLocation(juce::File::userApplicationDataDirectory)
            .getChildFile("SignalForge")
            .getChildFile(".cv290_trial");
    }

private:
    LicenseManager() { checkStoredLicense(); }

    void ensureTrialInitialized()
    {
        auto trialFile = getTrialFile();
        if (trialFile.existsAsFile())
        {
            auto content = trialFile.loadFileAsString().trim();
            auto tokens = juce::StringArray::fromTokens(content, "|", "");
            if (tokens.size() == 2)
            {
                const int64_t parsedStart = tokens[0].trim().getLargeIntValue();
                const juce::String storedSig = tokens[1].trim();
                if (parsedStart > 0 && storedSig.equalsIgnoreCase(computeTrialSignature(parsedStart)))
                {
                    trialStartEpochSeconds.store(parsedStart, std::memory_order_relaxed);
                    trialTampered.store(false, std::memory_order_relaxed);
                    return;
                }
            }

            // Corrupted or tampered trial file -> treat as expired
            trialTampered.store(true, std::memory_order_relaxed);
            return;
        }

        // First run: persist the trial start timestamp
        const int64_t nowSec = juce::Time::getCurrentTime().toMilliseconds() / 1000;
        trialFile.getParentDirectory().createDirectory();
        trialFile.replaceWithText(juce::String(nowSec) + "|" + computeTrialSignature(nowSec));
        trialStartEpochSeconds.store(nowSec, std::memory_order_relaxed);
        trialTampered.store(false, std::memory_order_relaxed);
    }

    juce::String computeTrialSignature(int64_t startEpochSeconds) const
    {
        const juce::String payload = "CV290-TRIAL-7D|" + juce::String(startEpochSeconds) + "|SFA-BOSEN-290-SECURE-KEY-2026";
        juce::SHA256 sha(payload.toUTF8());
        return sha.toHexString().toUpperCase().substring(0, 24);
    }

    bool verifyKey(const juce::String& email, const juce::String& serialKey) const
    {
        if (email.isEmpty() || serialKey.isEmpty())
            return false;

        // Shared secret matched against sfalabs.digital key generator
        const juce::String sharedSecret = "SFA-BOSEN-290-SECURE-KEY-2026";

        // Compare formatted output against serial format: XXXX-XXXX-XXXX-XXXX
        return serialKey.trim().equalsIgnoreCase(generateExpectedSerial(email, sharedSecret));
    }

    juce::String generateExpectedSerial(const juce::String& email, const juce::String& secret) const
    {
        const juce::String payload = email.toLowerCase().trim() + secret;
        juce::SHA256 sha(payload.toUTF8());
        auto rawHex = sha.toHexString().toUpperCase();

        // Format into 16-char product key: ABCD-EFGH-IJKL-MNOP
        return rawHex.substring(0, 4) + "-" +
               rawHex.substring(4, 8) + "-" +
               rawHex.substring(8, 12) + "-" +
               rawHex.substring(12, 16);
    }

    std::atomic<bool>    licenseValid { false };
    std::atomic<int64_t> trialStartEpochSeconds { 0 };
    std::atomic<bool>    trialTampered { false };
    juce::String         licensedEmail;
};
