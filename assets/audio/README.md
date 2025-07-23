# 🔊 KawaiiSec Audio Integration System

This directory contains the complete audio feedback system for KawaiiSec OS, providing kawaii sound effects for authentication, command execution, and system events.

## 🎵 Audio Files & Use Cases

| File Name     | Event / Use Case                      | Trigger Condition                                |
| ------------- | ------------------------------------- | ------------------------------------------------ |
| `denied.mp3`  | Wrong Password / Access Denied        | User inputs an incorrect password or fails auth |
| `welcome.mp3` | Correct Password / Successful Login   | User successfully authenticates                  |
| `did_it.mp3`  | Successful Command/Task Completion    | Terminal command or task completes successfully |
| `nani.mp3`    | Command Error / Failure               | Terminal command fails or encounters an error   |

**File specifications:**
- Format: MP3
- Duration: 1-3 seconds recommended  
- Volume: Moderate (not too loud!)
- Style: Kawaii/anime-inspired sound effects

## 🎧 Integration with KawaiiSec OS

The audio system is automatically integrated into:

### 🔐 Authentication Events
- **Wrong Password (`denied.mp3`)**: Triggered on authentication failures
- **Successful Login (`welcome.mp3`)**: Triggered on successful authentication

### ⌨️ Terminal Command Feedback  
- **Success (`did_it.mp3`)**: Plays when commands complete successfully (exit code 0)
- **Error (`nani.mp3`)**: Plays when commands fail (non-zero exit code)

### 🔍 Tool Integration
- **PinkMap**: Uses audio feedback for scan results and errors
- **Terminal Theme**: Automatic command success/failure feedback
- **Custom Scripts**: Can integrate via `kawaii-audio.sh`

## 🎵 Getting Kawaii Audio Files

### Option 1: Download Kawaii Sounds
Find cute anime-style sounds online and save them with the correct filenames.

### Option 2: Create Your Own
Record or generate kawaii sound effects. Popular choices:
- Authentication: Welcome chimes, denial buzzes
- Success: Achievement sounds, cute exclamations
- Error: "NANI?!" effects, surprised sounds

### Option 3: Convert Existing Sounds
Convert audio files to MP3 format:

```bash
# Using ffmpeg
ffmpeg -i input_sound.wav output_sound.mp3

# Using online converters (for convenience)
# just upload and download as MP3
```

## 🔧 Installation & Setup

### Step 1: Obtain Audio Files
1. Get your kawaii sound files (see above options)
2. Name them exactly: `denied.mp3`, `welcome.mp3`, `did_it.mp3`, `nani.mp3`
3. Place all files in this directory: `resources/sounds/`
4. Make sure they're readable: `chmod 644 *.mp3`

### Step 2: Install Audio Dependencies
Run the auto-installer:
```bash
# Source the audio system
source resources/scripts/kawaii-audio.sh

# Install dependencies for your OS
install_kawaii_audio_deps
```

### Step 3: Integrate with Your Shell
Add to your shell configuration (`~/.zshrc`, `~/.bashrc`):
```bash
# Source KawaiiSec audio system
if [[ -f "/path/to/KawaiiSec-OS/resources/scripts/kawaii-audio.sh" ]]; then
    source "/path/to/KawaiiSec-OS/resources/scripts/kawaii-audio.sh"
fi
```

### Step 4: Test the System
```bash
# Check system status
kawaii_audio_status

# Test individual sounds
kawaii_denied    # Test wrong password sound
kawaii_welcome   # Test correct password sound
kawaii_did_it    # Test success sound
kawaii_nani      # Test error sound
```

## 🐧 Linux Audio Players

The `pinkmap.sh` script automatically detects these audio players:
- `aplay` (ALSA)
- `paplay` (PulseAudio)  
- `mpg123` (MP3 player)
- `ffplay` (FFmpeg)

Install one if missing:
```bash
# Ubuntu/Debian
sudo apt install alsa-utils          # for aplay
sudo apt install pulseaudio-utils    # for paplay  
sudo apt install mpg123              # for mpg123
sudo apt install ffmpeg              # for ffplay

# Arch Linux
sudo pacman -S alsa-utils pulseaudio mpg123 ffmpeg

# CentOS/RHEL
sudo yum install alsa-utils pulseaudio-utils mpg123 ffmpeg
```

## 🚀 Advanced Usage

### Command Execution with Audio Feedback
```bash
# Execute command with automatic audio feedback
kawaii_exec "ls -la"                    # Success/error audio
kawaii_exec "invalid_command"           # Will play error sound

# Authentication with audio feedback  
kawaii_auth "sudo echo 'test'"          # Welcome/denied audio
```

### Custom Script Integration
```bash
#!/bin/bash
source "path/to/kawaii-audio.sh"

# Your authentication logic
if authenticate_user; then
    kawaii_welcome
    echo "Login successful!"
else
    kawaii_denied  
    echo "Access denied!"
    exit 1
fi

# Your command execution
if run_important_task; then
    kawaii_did_it
    echo "Task completed!"
else
    kawaii_nani
    echo "Task failed!"
fi
```

## 🌐 Cross-Platform Support

- **macOS**: Uses `afplay` (built-in, no setup needed)
- **Linux**: Auto-detects `paplay`, `aplay`, `mpg123`, or `ffplay`
- **Windows/WSL**: Uses PowerShell or `mpg123`
- **Other OS**: Gracefully disables audio with no errors

## 🛠️ Available Functions

- `kawaii_denied()` - Play wrong password sound
- `kawaii_welcome()` - Play correct password sound  
- `kawaii_did_it()` - Play success sound
- `kawaii_nani()` - Play error sound
- `kawaii_exec(cmd)` - Execute command with audio feedback
- `kawaii_auth(cmd)` - Execute auth command with audio feedback
- `kawaii_audio_status()` - Show system status
- `install_kawaii_audio_deps()` - Install audio dependencies

## 🌸 Note

Remember to use sounds ethically and respect copyright! Use royalty-free or self-created kawaii sounds only.

*Stay cute, stay secure!* 💖✨ 