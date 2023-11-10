# Requirements
Before installing VIP please check whether your system meets the following requirements:

- [POSIX compatible system](https://en.wikipedia.org/wiki/POSIX#POSIX-oriented_operating_systems) (e.g. Linux, macOS, [Windows Subsystem for Linux](https://learn.microsoft.com/en-us/windows/wsl/about)) with x86_64 architecture (AArch64 not supported)
- Bash ≥ 3.2
- Java ≥ 11
- [Apptainer](https://apptainer.org/docs/admin/main/installation.html#install-from-pre-built-packages) (setuid installation)
- 8GB RAM <sup>1</sup>
- 150GB disk space

1) The memory requirements differ per workflow and depend, on the size of your input data, the scheduler that you use, the amount of parallelization. For example, executing VIP using a job scheduler will reduce the memory requirements on the system submitting the jobs to 1-2GB.

## Optional
VIP auto-detects whether [Slurm](https://slurm.schedmd.com/overview.html) is available on the system and, if available, will schedule its jobs with Slurm. Otherwise, the jobs will be submitted on the local system. 
