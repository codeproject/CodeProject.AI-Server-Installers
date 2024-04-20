# Managing disk usage

Docker can be a space hog. Two things can be done to reclaim space

1. Install the "Disk Usage" docker desktop extension and use it to remove build cache, hanging images, or anything else you don't need

2. Compact the vdisk

   After cleaning out what you don't need (step 1), do the following

    - Open a command window using admin rights
    - `wsl --shutdown`
    - `diskpart`
    - You'll now see the diskpart prompt. 
    - Enter `select vdisk file="C:\Users\your-username\AppData\Local\Docker\wsl\data\ext4.vhdx"`
    - `compact vdisk`
    - `exit`

Your docker VM disk should now be as compact as it can get

# Permissions issues

1. `docker login --username` - this will prompt you for your password. Enter your docker hub password.
2. `docker login --username` - same, but instead of your docker hub password, use a 