---
title: xterm 终端模拟器
author: 李嘉明
createTime: 2024/12/03 16:21:13
permalink: /article/rnk7g824/
tags:
  - 工具
---

官网：<https://xtermjs.org/>

**vue2 支持版本**

```json
"xterm": "^4.19.0",
"xterm-addon-attach": "^0.6.0",
"xterm-addon-fit": "^0.5.0",
"xterm-addon-search": "^0.9.0",
"xterm-addon-web-links": "^0.6.0"
```

## xterm-addon-web-links

xterm-addon-web-links 是一个用于在 xterm.js 终端中处理网页链接的附加组件。它允许用户在终端中点击链接并在浏览器中打开这些链接。这个功能对于需要在终端中处理 URL 的应用程序非常有用。

```js
import { Terminal } from 'xterm';
import { WebLinksAddon } from 'xterm-addon-web-links';

const terminal = new Terminal();
const webLinksAddon = new WebLinksAddon();

terminal.loadAddon(webLinksAddon);
terminal.open(document.getElementById('terminal'));
```

## xterm-addon-search

xterm-addon-search 是一个用于 xterm.js 的附加组件，提供了强大的终端搜索功能。这个插件允许用户在终端输出中查找文本，并支持高亮显示匹配项、向前和向后的搜索等功能。

```js
import { Terminal } from 'xterm';
import { SearchAddon } from 'xterm-addon-search';

let dom = this.$refs.terminal;
let terminal = new Terminal({
  useStyle: true,
  cursorBlink: true,
});
let searchAddon = new SearchAddon();
terminal.loadAddon(searchAddon);
this.searchAddon = searchAddon;
terminal.open(dom);
Terminal._initialized = true;

// 查询方法
function search() {
  this.searchAddon.findNext(this.inputText, {
    regex: true,
    decorations: {
      matchBackground: '#E6A23C',
      activeMatchBackground: '#909399',
    },
  });
}
```

## xterm-addon-fit

xterm-addon-fit 是一个用于 xterm.js 的附加组件，旨在使终端自动适应其容器的大小。这对于需要在动态调整大小的界面中使用终端时非常有用，例如在响应式设计或嵌入式应用中。

```js
import { Terminal } from 'xterm';
import { FitAddon } from 'xterm-addon-fit';

let dom = this.$refs.terminal;
let terminal = new Terminal({
  useStyle: true,
  cursorBlink: true,
});
let fitAddon = new FitAddon();
terminal.loadAddon(fitAddon);
terminal.open(dom);
fitAddon.fit();
Terminal._initialized = true;

// 更新方法
let fit = function () {
  fitAddon.fit();
  const dimensions = fitAddon.proposeDimensions();
  if (dimensions.cols && dimensions.rows) {
    terminal.resize(dimensions.cols - 1, dimensions.rows);
  }
};

window.addEventListener(
  'resize',
  debounce(function () {
    fit();
  }),
  100
);
setTimeout(fit, 1000);
```

## xterm-addon-attach

xterm-addon-attach 是一个用于 xterm.js 的附加组件，允许将终端与后端进程进行连接。这个插件特别适合于需要将终端输出与后端服务（如 Node.js、WebSocket 等）进行实时交互的应用场景。

### 后端代码

```js
const express = require('express');
const expressWs = require('express-ws');
const app = express();
expressWs(app);
const pty = require('node-pty');
const os = require('os');
const shell = os.platform() === 'win32' ? 'powershell.exe' : 'bash';
const termMap = new Map(); //存储 pty 实例，通过 pid 映射
function nodeEnvBind() {
  //绑定当前系统 node 环境
  const term = pty.spawn(shell, ['--login'], {
    name: 'xterm-color',
    cols: 80,
    rows: 24,
    cwd: process.env.HOME,
    env: process.env,
  });
  termMap.set(term.pid, term);
  return term;
}
//解决跨域问题
app.all('*', function (req, res, next) {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', 'Content-Type');
  res.header('Access-Control-Allow-Methods', '*');
  next();
});

//服务端初始化
app.post('/terminal', (req, res) => {
  // 改造为允许多个终端访问的场景
  const term = nodeEnvBind(req);
  res.send(term.pid.toString());
  res.end();
});
app.ws('/socket/:pid', (ws, req) => {
  const pid = parseInt(req.params.pid);
  const term = termMap.get(pid);
  term.on('data', function (data) {
    ws.send(data);
  });
  ws.on('message', (data) => {
    term.write(data);
  });
  ws.on('close', function () {
    term.kill();
    termMap.delete(pid);
  });
});
```

### 客户端

```js
let dom = this.$refs.terminal;
let Base64 = require('js-base64').Base64;
let terminal = new Terminal({
  useStyle: true,
  cursorBlink: true,
});
terminal.open(dom);
Terminal._initialized = true;

const socketURL = 'ws://127.0.0.1:4000/socket/';

// 参数1： 要连接的 URL；这应当是 WebSocket 服务器会响应的 URL。
// 参数2： 一个协议字符串或一个协议字符串数组。这些字符串用来指定子协议，这样一个服务器就可以实现多个 WebSocket 子协议
const ws = new WebSocket(socketURL);

import axios from 'axios';

//初始化当前系统环境，返回终端的 pid，标识当前终端的唯一性
const initSysEnv = async (term: Terminal) =>
  await axios
    .post('http://127.0.0.1:4000/terminal')
    .then((res) => res.data)
    .catch((err) => {
      throw new Error(err);
    });
const pid = await initSysEnv(term),
  websocket = new WebSocket(socketURL + pid);

import { AttachAddon } from 'xterm-addon-attach';
attachAddon = new AttachAddon(websocket);
term.loadAddon(attachAddon);

websocket.onmessage = function (sss) {
  // 终端写入一行方法，注意与后端沟通的编码格式，这里采用 Base64 进行解码
  terminal.writeln(Base64.decode(sss.data));
};

websocket.onerror = function (e) {
  console.log(e);
  alert('连接错误请刷新再试');
};

// 还可以这样绑定事件
websocket.addEventListener('message', function (recv) {
  let data = event.data.slice(1);
  switch (event.data[0]) {
    case '1':
    case '2':
    case '3':
      terminal.write(Base64.decode(data));
      break;
  }
});
// 当我们终端键入的时候，onData 返回的都是 UTF-16/UCS-2 编码的，要让系统认识得输出成 UTF-8 编码
terminal.onData((e) => {
  websocket.send('0' + Base64.encode(e));
});
```
