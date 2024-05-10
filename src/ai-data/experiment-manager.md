# Experiment-Manager

## 查看运行状态

查看 ExperimentManager Web 运行状态：

```bash
kubectl get deploy -n t9k-system -l app=experiment-management-web
```

```
NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
experiment-management-web   1/1     1            1           13d
```
Web 一般没有日志，直接通过浏览器进入 Web 页面查看是否工作正常即可。
