# 生成 T9k 产品镜像列表

这里的操作在 ks-clusters/tools/offline-t9k 中进行：

```bash
$ cd ~/ansible/ks-clusters/tools/offline-t9k
```

1）确认您完成了[下载 Helm Chart](../offline/prepare-offline-packages/k8s-components.md#下载-helm-chart)。

2）然后准备 values.yaml，您可以在 [sample]() 的基础上修改。您需要确保该 values.yaml 对容器镜像的设置与实际安装使用的一致。

3）生成镜像列表，保存在 images.list：

```bash
$ ./generate-image-list.sh --values values.yaml --config productlist/t9k-2024-03-25.list
```

请注意这里的提示：

```
The generation script may miss some specially set images.
You can use the following command to list them:

for file in $(ls temp | grep -E "^gen\..*\.yaml$"); do
   cat temp/$file | grep t9kpublic | grep -v "image:";
done
```

4）您需要手动处理这里的其他镜像，来生成最终的 `images.list`。
