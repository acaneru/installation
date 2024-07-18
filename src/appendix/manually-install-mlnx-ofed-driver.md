# 手动安装 MLNX_OFED 驱动

从 NVIDIA 官网下载  NVIDIA MLNX_OFED 驱动，根据实际情况选择对应的版本。例如：MLNX_OFED_LINUX-5.9-0.5.6.0-ubuntu20.04-x86_64.tgz

<aside class="note">
<div class="title">注意</div>

如有必要通过命令行下载，可以参考 [Installing MLNX_OFED Using apt-get](https://docs.nvidia.com/networking/display/MLNXOFEDv562090/Installing+MLNX_OFED#InstallingMLNX_OFED-ofedinstallationusingapt-getInstallingMLNX_OFEDUsingapt-get)。

</aside>

从本地复制 [NVIDIA MLNX_OFED](https://network.nvidia.com/products/infiniband-drivers/linux/mlnx_ofed/) 驱动到目标节点上：

```bash
$ ssh <node> -- mkdir -p tensorstack-install/mellanox
$ rsync -aP MLNX_OFED_LINUX-5.9-0.5.6.0-ubuntu20.04-x86_64.tgz \
    <node>:~/tensorstack-install/mellanox/
```

在节点运行：

```bash
$ cd ~/tensorstack-install/mellanox
$ tar zxvf ./MLNX_OFED_LINUX-5.9-0.5.6.0-ubuntu20.04-x86_64.tgz
$ cd ./MLNX_OFED_LINUX-5.9-0.5.6.0-ubuntu20.04-x86_64
```

确认节点没有安装 mlnx 相关的包：

```bash
$ apt list --installed | grep -i mlnx 
```

安装之前使用 tmux，避免 ssh 网络连接影响安装过程：

```bash
$ tmux
```

使用安装脚本进行安装：

```bash
$ sudo ./mlnxofedinstall --all --force
```

两个命令行参数的含义：

```bash
--all              Install all available packages
--force            Force installation，used for unattended installation
```

安装过程的输出：

```bash
Logs dir: /tmp/MLNX_OFED_LINUX.175111.logs
General log file: /tmp/MLNX_OFED_LINUX.175111.logs/general.log

Below is the list of MLNX_OFED_LINUX packages that you have chosen
(some may have been added by the installer due to package dependencies):

ofed-scripts
mlnx-tools
…
```

安装完成后的提示：

```bash
The firmware for this device is not distributed inside Mellanox driver: 31:00.0 (PSID: LNV0000000016)
To obtain firmware for this device, please contact your HW vendor.
         
Failed to update Firmware.     
See /tmp/MLNX_OFED_LINUX.175111.logs/fw_update.log                
Device (31:00.0):              
        31:00.0 Infiniband controller: Mellanox Technologies MT28908 Family [ConnectX-6]             
        Link Width: x16        
        PCI Link Speed: 16GT/s 
         
Installation passed successfully                                  
To load the new driver, run:   
/etc/init.d/openibd restart
```

其中的日志文件，内容为：

```bash
$ /tmp/MLNX_OFED_LINUX.175111.logs/fw_update.log
The firmware for this device is not distributed inside Mellanox driver: 31:00.0 (PSID: LNV0000000016)
To obtain firmware for this device, please contact your HW vendor.

EXIT_STATUS: 2
```
