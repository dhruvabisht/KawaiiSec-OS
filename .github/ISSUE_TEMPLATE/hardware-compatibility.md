---
name: 🖥️ Hardware Compatibility Report
about: Report hardware test results for the compatibility matrix
title: '[Hardware Report] [Brand Model] - [Status]'
labels: ['hardware-compatibility', 'testing', 'community']
assignees: []

---

## 🖥️ Hardware Information

**System Type:** 
- [ ] Physical Laptop
- [ ] Physical Desktop
- [ ] Virtual Machine (specify platform)
- [ ] Cloud Instance (specify provider)

**Brand/Model:** 
<!-- e.g., ThinkPad T480, Dell XPS 13, Custom Build, etc. -->

**Specifications:**
- **CPU:** 
- **RAM:** 
- **Storage:** 
- **Graphics:** 
- **WiFi Chipset:** 
- **Ethernet Controller:** 
- **Audio System:** 

## 🧪 Test Results

**Overall Compatibility Score:** _%

### 📊 Component Testing Results

| Component | Status | Notes |
|-----------|--------|-------|
| **BIOS/UEFI Boot** | ✅ ⚠️ ❌ |  |
| **Live Boot** | ✅ ⚠️ ❌ |  |
| **Installation** | ✅ ⚠️ ❌ |  |
| **Ethernet** | ✅ ⚠️ ❌ |  |
| **WiFi** | ✅ ⚠️ ❌ |  |
| **Audio** | ✅ ⚠️ ❌ |  |
| **Graphics** | ✅ ⚠️ ❌ |  |
| **Display Scaling** | ✅ ⚠️ ❌ |  |
| **USB Devices** | ✅ ⚠️ ❌ |  |
| **Bluetooth** | ✅ ⚠️ ❌ |  |
| **Webcam** | ✅ ⚠️ ❌ |  |
| **Suspend/Resume** | ✅ ⚠️ ❌ |  |
| **Power Management** | ✅ ⚠️ ❌ |  |

### 🔧 Issues and Workarounds

**Issues Encountered:**
<!-- Describe any problems you experienced -->

**Workarounds Used:**
<!-- List any steps needed to resolve issues -->

**Required Drivers/Firmware:**
<!-- List any additional drivers or firmware packages needed -->

## 📄 Automated Test Report

**Did you run the automated test?**
- [ ] Yes, using `make hwtest`
- [ ] Yes, using `kawaiisec-hwtest.sh`
- [ ] No, manual testing only

**Test Report Attachment:**
<!-- Please attach your ~/kawaiisec_hw_report.txt file -->

## 📋 Testing Details

**KawaiiSec OS Version:** 
<!-- e.g., 1.0.0, git commit hash, etc. -->

**Test Date:** 
<!-- YYYY-MM-DD -->

**Testing Method:**
- [ ] Live USB boot
- [ ] Full installation
- [ ] Virtual machine
- [ ] Container/Docker

**Additional Context:**
<!-- Any other information that might be helpful -->

## 🎯 Recommendations

**Would you recommend this hardware for KawaiiSec OS?**
- [ ] ✅ Highly recommended - Everything works perfectly
- [ ] ⚠️ Recommended with minor issues - Usable with workarounds
- [ ] ⚠️ Not recommended - Major functionality broken
- [ ] ❌ Incompatible - Cannot run KawaiiSec OS

**Comments:**
<!-- Additional thoughts or recommendations -->

---

## 📝 For Maintainers

- [ ] Verified test report
- [ ] Added to hardware compatibility matrix
- [ ] Updated documentation if needed
- [ ] Added any required workarounds to troubleshooting

**Matrix Table Entry:**
```markdown
| **[Brand Model]** | [CPU] | [RAM] | [Storage] | [WiFi] | [Ethernet] | ✅/✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | [Issues] | [Date] | [Tester] |
```

---

🌸 **Thank you for contributing to KawaiiSec OS hardware compatibility!** 🌸 