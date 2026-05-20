# TouchAble 可触：原始讨论整理

日期：2026-05-20

## 1. 最初问题

Phil 提出：

Mac 的 trackpad 有震动功能，能不能让触控体验进一步增强？比如手指在触控板上滑动时，带来更强的交互体验。

初始判断：

- 可以做，但不能把它理解成“随意控制马达震动”。
- Apple 公开 API 更适合做短促的触觉反馈，而不是连续震动波形。
- 最适合的方向是“触觉标点”：在关键交互点轻轻提示。

## 2. 第一轮验证：触觉能不能触发

写了 `prototypes/haptic-demo.swift`。

验证结果：

- 当前 Mac 可以通过 `NSHapticFeedbackManager` 触发真实触觉反馈。
- `generic`、`alignment`、`levelChange` 都可用。
- Phil 反馈：确实有感觉。

体验命令：

```bash
cd /Users/philrobin/work/touchable
swift prototypes/haptic-demo.swift ramp
swift prototypes/haptic-demo.swift generic
swift prototypes/haptic-demo.swift align
swift prototypes/haptic-demo.swift level
```

## 3. 第二轮想法：边缘感

Phil 提出：

希望手指滑到不同区域时，有明显的边缘感。

实现了 `prototypes/edge-haptic-demo.swift`。

原型做法：

- 用光标位置作为触控滑动的代理。
- 光标靠近屏幕边缘时触发 `alignment`。
- 光标跨越屏幕网格区域时触发 `levelChange`。
- 加入节流，避免高频触发。

体验命令：

```bash
cd /Users/philrobin/work/touchable
swift prototypes/edge-haptic-demo.swift 60
```

安全判断：

- 当前方式使用 Apple 公开 AppKit API。
- 不直接控制马达。
- 不做持续高频震动。
- 风险很低，类似系统自己在 Force Touch、对齐辅助等场景中的反馈。

## 4. 第三轮命名与立项

Phil 提出名字：

`touchalbe 可触的`

讨论后修正：

- 标准拼写是 `touchable`。
- 作为品牌可以写成 `TouchAble 可触`。
- 内部项目目录定为 `/Users/philrobin/work/touchable`。

当前定位：

TouchAble 可触，不只是一个震动脚本，而是一个让 Mac 界面“摸得到”的触觉增强产品。

## 5. 第四轮产品方向

初步产品判断：

TouchAble 不应该做成“触控板一直震”的玩具，而应该做成 Mac 的一层“触觉层”。

关键设计原则：

- 少而准。
- 像系统原生功能。
- 平时安静，需要时出现。
- 不是震动，是触觉标点。

最初四个场景：

- 屏幕边缘感。
- 区域刻度感。
- 滚动尽头感。
- 窗口吸附感。

## 6. 第五轮突破：语义触感

Phil 提出更关键的想法：

希望它与光标的变化匹配。比如：

- 光标识别到一个按钮。
- 光标识别到文字。
- 光标选中文字。
- 不同对象都有不同感触。

这让项目从“位置触感”升级成“语义触感”。

## 7. 语义探测验证

写了 `prototypes/semantic-probe.swift`。

它不触发震动，只打印光标下面的对象类型。

验证结果：

系统能识别到真实 UI 角色，包括：

- `AXButton`
- `AXStaticText`
- `AXTextArea`
- `AXPopUpButton`
- `AXMenuBar`
- `AXMenuBarItem`

说明全局语义探测链路可行。

体验命令：

```bash
cd /Users/philrobin/work/touchable
swift prototypes/semantic-probe.swift 30
```

## 8. 语义触觉原型验证

Phil 说没有感觉，因为当时跑的是只打印、不震动的探针。

于是写了 `prototypes/semantic-haptic-demo.swift`。

映射方式：

- 按钮、菜单、链接类：`alignment`
- 文字、输入框、滑杆类：`levelChange`
- 普通区域：安静
- 只有语义区域变化时触发，避免烦人

体验命令：

```bash
cd /Users/philrobin/work/touchable
swift prototypes/semantic-haptic-demo.swift 45
```

验证结果：

终端输出显示多次识别并触发：

- `pulse zone=text role=AXStaticText`
- `pulse zone=control role=AXButton`
- `pulse zone=input role=AXTextArea`
- `pulse zone=control role=AXPopUpButton`

Phil 反馈：

“哇，这种感觉太惊艳了。”

这是目前最重要的产品验证点。

## 9. 当前核心洞察

TouchAble 最有价值的方向不是震动，而是“界面语义变成触觉”。

也就是说：

- 按钮不只是看起来可点，而是摸起来可点。
- 文字不只是看起来是文字，而是摸起来有纸面感。
- 输入框不只是视觉边框，而是摸起来能输入。
- 边缘不只是屏幕尽头，而是摸起来有墙。

## 10. 当前项目状态

已完成：

- 项目目录建立。
- 原型脚本落盘。
- 初步研究文档落盘。
- 语义识别跑通。
- 语义触觉跑通。
- 初步产品方向清晰。

尚未完成：

- 正式菜单栏 App。
- 权限提示和授权流程。
- 参数面板。
- 真实多 App 兼容性测试。
- “选中文字”的专门识别。
- 滚动尽头和窗口吸附。
- 产品定位、目标用户、商业化策略。
