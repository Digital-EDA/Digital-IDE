命名规则：

```html
<level>.<module>.<name>
```

比如 `info.monitor.update-pl`

- info: 通知等级
- monitor: 功能模块，此处是监视器
- name: 对于模块功能的描述，可以是更加复杂的层级关系，比如 name.subname.subsubname

上述的一个描述代表了一个如此的功能描述：

该功能描述了 monitor 这个功能模块的一个名叫 update-pl 的功能，该功能在进行输出时，输出等级为 info.

有的时候一个功能下可能希望更加细粒度的描述，比如说上面的 update-pl，这个功能的描述文本可以作为最终的主体文本（text），也可以作为最终描述该功能组件的标题（title），也可以是该功能的一个按钮（button）。总之，有的时候我们还希望指定该功能描述的一个实体/组件。所以下面的格式也是符合要求的：

```html
<level>.<module>.<name>.<component>
```

比如以下的三组描述：

```json
{
    "info.vcd-view.load.button": "加载",
    "info.vcd-view.load.title": "加载",
    "info.vcd-view.load.text": "正在加载 ..."
}
```

它们都代表了 `vcd-view` 这个功能模块的名为 `load` 的功能的中文翻译，但是这三个文本分别描述了实施这个 load 功能的功能组件：

- `info.vcd-view.load.button` 描述了 button 位置上需要渲染的文本
- `info.vcd-view.load.title` 描述了 title 位置上需要渲染的文本
- `info.vcd-view.load.text` 描述了 text 位置上需要渲染的文本

关于如何进行规定 `<component>` 位置上的值，应该由产品经理来规定。