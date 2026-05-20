# 下一窗口开场 Brief

如果换一个窗口继续讨论，可以从这里开始。

## 当前项目

项目名：TouchAble 可触

目录：

```bash
/Users/philrobin/work/touchable
```

## 我们已经验证

1. Mac 触控板可以通过公开 API 触发触觉反馈。
2. 光标靠近屏幕边缘时，可以做出“边缘感”。
3. macOS Accessibility 可以识别光标下面的真实 UI 对象。
4. 按钮、文字、输入框等对象变化可以映射成不同触觉。
5. 语义触觉原型已经让 Phil 明确感到惊艳。

## 最重要原型

```bash
cd /Users/philrobin/work/touchable
swift prototypes/semantic-haptic-demo.swift 45
```

这个脚本是当前项目的核心体验验证。

## 下一步最值得讨论的问题

1. TouchAble 到底是工具、体验产品，还是未来系统插件？
2. 第一版菜单栏 App 应该有哪些功能？
3. 哪些触觉反馈是默认开的，哪些应该默认关？
4. 触觉词典怎么设计？
5. 是否要做一个 Playground 演示窗口？
6. 是否要沉淀成正式 Swift/Xcode 项目？
7. 是否需要考虑发布、隐私说明和商业化？

## 建议下一步

先不要急着写完整 App。

建议先做 3 件事：

1. 设计触觉词典：按钮、文字、输入框、链接、菜单、选区、边缘分别是什么手感。
2. 做一个可调参原型：把节流、角色映射、开关做成配置。
3. 再启动正式菜单栏 App。

## 新窗口可以这样开场

“我们继续 TouchAble 可触项目。请先读 `/Users/philrobin/work/touchable/docs/next-session-brief.md`、`docs/product-brief.md` 和 `docs/raw-discussion.md`，然后和我一起做正式产品策划。”
