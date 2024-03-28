# S3 Service（external）

LakeFS 使用一个独立的外部 S3 服务来存储对象数据，该 S3 服务可选择 <a target="_blank" rel="noopener noreferrer" href="https://min.io/">Minio</a> 或 <a target="_blank" rel="noopener noreferrer" href="https://docs.ceph.com/en/quincy/radosgw/">Ceph RGW</a> 等。管理员可以通过 s3cmd 命令行或 S3 服务提供的网页界面查看 S3 服务是否正常运行。
