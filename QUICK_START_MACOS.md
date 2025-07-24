# 🌸 KawaiiSec OS - Quick Start for macOS Users

Since you're running on **macOS**, you'll need a Linux environment to build KawaiiSec OS. Here are your **fastest options**:

## 🚀 Option 1: Docker (Recommended - Fastest Setup)

**Prerequisites:** Docker Desktop installed

```bash
# 1. Install Docker Desktop (if not already installed)
brew install --cask docker

# 2. Start Docker Desktop application

# 3. Build KawaiiSec OS using Docker
./docker-build.sh
```

That's it! The script will:
- Build a Debian container with all required tools
- Build the KawaiiSec OS ISO inside the container
- Output the ISO to your current directory

## 🌐 Option 2: Vagrant + VirtualBox

**Prerequisites:** VirtualBox and Vagrant installed

```bash
# 1. Install prerequisites
brew install --cask virtualbox vagrant

# 2. Use the provided Vagrantfile
cp Vagrantfile.builder Vagrantfile

# 3. Start and provision the VM
vagrant up

# 4. SSH into the VM and build
vagrant ssh
cd KawaiiSec-OS
sudo ./build-iso.sh
```

## ☁️ Option 3: GitHub Actions (Zero Local Setup)

**Prerequisites:** GitHub account and repository access

1. **Push to GitHub:** Commit your changes and push to your repository
2. **Trigger Build:** Go to Actions tab → "Build KawaiiSec OS ISO" → "Run workflow"
3. **Download ISO:** Once complete, download the ISO from the workflow artifacts

## 🎯 Which Option Should You Choose?

| Option | Setup Time | Build Time | Best For |
|--------|------------|------------|----------|
| **Docker** | 5 minutes | 30-60 min | Quick local builds |
| **Vagrant** | 10 minutes | 30-60 min | Persistent dev environment |
| **GitHub Actions** | 0 minutes | 45-90 min | No local resources needed |

## 📋 System Requirements

**For Docker/Vagrant:**
- **RAM:** 8GB+ allocated to Docker/VM
- **Storage:** 20GB+ free space
- **Internet:** Fast connection for downloading packages

**For GitHub Actions:**
- GitHub repository with Actions enabled
- No local requirements

## 🚀 Quick Commands

### Docker Build
```bash
# Simple build
./docker-build.sh

# Clean build (remove previous Docker image)
./docker-build.sh --clean

# Check if Docker is running
docker info
```

### Vagrant Build
```bash
# Start VM and build
vagrant up && vagrant ssh -c "cd KawaiiSec-OS && sudo ./build-iso.sh"

# Check VM status
vagrant status

# Stop VM when done
vagrant halt
```

### Manual GitHub Actions
```bash
# Push changes to trigger build
git add . && git commit -m "Build ISO" && git push

# Or trigger manually via GitHub web interface
# → Actions → Build KawaiiSec OS ISO → Run workflow
```

## 🎉 After Building

Once you have the ISO:

1. **Test in UTM (Apple Silicon recommended):**
   ```bash
   brew install --cask utm
   # Import ISO in UTM and create VM
   ```

2. **Test in VirtualBox:**
   ```bash
   brew install --cask virtualbox
   # Create new VM and mount ISO
   ```

3. **Create bootable USB:**
   ```bash
   # Find USB device
   diskutil list
   
   # Create bootable USB (replace /dev/diskX with your USB)
   sudo dd if=kawaiisec-os-*.iso of=/dev/diskX bs=4M
   ```

## 🔍 Troubleshooting

**Docker Issues:**
- Ensure Docker Desktop is running
- Increase Docker memory allocation to 8GB+
- Try `docker system prune` if running out of space

**Vagrant Issues:**
- Enable virtualization in BIOS/UEFI
- Increase VM memory in Vagrantfile if needed
- Use `vagrant reload --provision` to restart

**GitHub Actions Issues:**
- Check Actions tab for detailed logs
- Ensure repository has Actions enabled
- Build may take longer due to shared runners

## 💡 Pro Tips

1. **Parallel Builds:** Use GitHub Actions while setting up local environment
2. **Resource Allocation:** Give Docker/VirtualBox as much RAM as possible
3. **Network:** Use wired connection for faster package downloads
4. **Storage:** Keep 30GB+ free space for build artifacts

## 🆘 Need Help?

- **Docker:** Check `docker logs` and Docker Desktop dashboard
- **Vagrant:** Run `vagrant status` and check VirtualBox console
- **GitHub:** Check Actions logs and workflow status
- **General:** See `BUILD_ON_MACOS.md` for detailed instructions

Happy building! 🌸 