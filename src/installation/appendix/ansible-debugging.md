# ansible debugging

## 常用调试方法

ansible-playbook 在运行时会输出调试信息，例如：

```
TASK [kubernetes/control-plane : Kubeadm | Initialize first master] ******************************************************************
fatal: [pek01]: FAILED! => {"attempts": 3, "changed": true, "cmd": ["timeout", "-k", "300s", "300s", "/usr/local/bin/kubeadm", "init", "--config=/etc/kubernetes/kubeadm-config.yaml", "--ignore-preflight-errors=all", "--skip-phases=addon/coredns", "--upload-certs"], "delta": "0:05:00.008708", "end": "2024-06-17 08:39:51.635807", "failed_when_result": true, "msg": "non-zero return code", "rc": 124, "start": "2024-06-17 08:34:51.627099", "stderr": "W0617 08:34:51.673472   36882 utils.go:69] The recommended value for \"clusterDNS\" in \"KubeletConfiguration\" is: [10.233.0.10]; the provided value is: [169.254.25.10]", "stderr_lines": ["W0617 08:34:51.673472   36882 utils.go:69] The recommended value for \"clusterDNS\" in \"KubeletConfiguration\" is: [10.233.0.10]; the provided value is: [169.254.25.10]"], "stdout": "[init] Using Kubernetes version: v1.28.6\n[preflight] Running pre-flight checks\n[preflight] Pulling images required for setting up a Kubernetes cluster\n[preflight] This might take a minute or two, depending on the speed of your internet connection\n[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'", "stdout_lines": ["[init] Using Kubernetes version: v1.28.6", "[preflight] Running pre-flight checks", "[preflight] Pulling images required for setting up a Kubernetes cluster", "[preflight] This might take a minute or two, depending on the speed of your internet connection", "[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'"]}
```

调试信息包括具体执行的命令和运行结果等详细信息。在相应节点上运行调试信息中的命令，通常能够复现出现的错误。如果需要更多信息，可依照本章提供的方法进一步进行调试。

### verbosity flag

设置命令行参数 `-v` 可以查看更详细的调试信息，例如：

```bash
ansible-playbook playbook.yml -v
```

添加更多的 "v" 可以查看更详细的信息，最低为 `-v`，最高为 `-vvvvvv`，一般使用 `-vvv` 即可。

### ansible debugger

ansible 内置了一个断点调试工具 debugger。它最简单的开启方式是设置环境变量 `ANSIBLE_ENABLE_TASK_DEBUGGER`。开启断点调试工具后，当某个 Task 失败时，会自动进入 debugger 环境。你可以在 debugger 环境中通过 p (print)、r (redo)、c (continue)、q (quit) 等命令进行调试：

```bash
ANSIBLE_ENABLE_TASK_DEBUGGER=True ansible-playbook playbook.yml
```

详细的使用方式参考：<a target="_blank" rel="noopener noreferrer" href="https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_debugger.html">Debugging tasks</a>。

### debug task

如果想查看当 playbook 运行到某个 Task 时节点的具体情况，可以在 playbook 中插入一个 debug Task，运行某些命令并打印输出，示例如下：

```yaml
- name: Execute uname -a
  ansible.builtin.shell: uname -a
  register: result

- name: Print result
  ansible.builtin.debug:
    msg: "DEBUG: {{ result }}"
```

详细的使用方式参考：<a target="_blank" rel="noopener noreferrer" href="https://docs.ansible.com/ansible/latest/collections/ansible/builtin/debug_module.html">ansible.builtin.debug module</a>。

### ansible tags

设置命令行参数 `--tags` 或者 `skip-tags` 来只执行一部分任务。

Kubespray 使用的所有 Tag 见 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes-sigs/kubespray/blob/master/docs/ansible/ansible.md#ansible-tags">Ansible tags</a>。

只执行带有指定 tag 的 Task：

```bash
ansible-playbook playbook.yml --tags tag1,tag2,tag3
```

跳过带有指定 tag 的 Task：

```bash
ansible-playbook playbook.yml --skip-tags tag1,tag2,tag3
```

> 注意：具有 Tag "Always" 的任务一定会被执行。

### 查看所有 Task

设置命令行参数 `--list-tasks` 来查看 playbook 中所有将要执行的 Task（该命令不会执行 Task）：

```bash
ansible-playbook playbook.yml --list-tasks
```

`--list-tasks` 可以结合 [ansible tags](#ansible-tags) 等参数一起使用，输出的结果是当前设置下将要执行的 Task。

### 逐步执行

设置命令行参数 `--step` 可以让 ansible 逐步执行所有的 Task，并在每一个 Task 开始前询问是否执行：

```bash
ansible-playbook playbook.yml --step
```

执行 Task 前的询问信息：

```bash
Perform task: TASK: Gathering Facts (N)o/(y)es/(c)ontinue: 
```

其含义如下：

* No: 跳过这个 Task
* yes: 执行这个 Task
* continue: 执行这个 Task 及后续所有的 Task（不再逐步询问）

> 注意：Kubespray 是一个相当长的 Playbook，包含了上千个 Task。逐步执行会需要较长时间。在需要逐步执行调试时，建议通过 [ansible tags](#ansible-tags) 指定其中一部分 Task 来执行。

