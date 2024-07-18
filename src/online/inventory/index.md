# 设置 ansible inventory

我们使用 <a target="_blank" rel="noopener noreferrer" href="https://docs.ansible.com/">ansible</a> 安装 K8s 及各种辅助组件，因此，我们需要准备一台电脑作为 <a target="_blank" rel="noopener noreferrer" href="https://docs.ansible.com/ansible/latest/network/getting_started/basic_concepts.html">ansible 控制节点</a>，以运行 ansible 命令，并在这个控制节点上，准备 ansible 的 <a target="_blank" rel="noopener noreferrer" href="https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html">inventory</a>。

<figure class="architecture">
  <img alt="ansible" src="../../assets/online/inventory.drawio.svg" width="80%" />
  <figcaption>图 1：安装了 ansible 的控制节点根据 inventory 和 playbook 的定义自动化管理和配置集群节点，以安装 K8s 及其组件</figcaption>
</figure>
