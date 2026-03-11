#! /usr/bin/env python3
# Copyright (c) 2024 Huawei Technologies Co., Ltd.
# openUBMC is licensed under Mulan PSL v2.
# You can use this software according to the terms and conditions of the Mulan PSL v2.
# You may obtain a copy of Mulan PSL v2 at:
#         http://license.coscl.org.cn/MulanPSL2
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
# EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
# MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
# See the Mulan PSL v2 for more details.
import logging
import json
import os
import ssl
from http.server import HTTPServer, SimpleHTTPRequestHandler


class FileServer(SimpleHTTPRequestHandler):    
    def do_POST(self):
        # 仅处理multipart/form-data类型
        if "multipart/form-data" not in self.headers.get("Content-Type", ""):
            self._send_resp(400, {"status": "failed", "msg": "Only multipart/form-data supported"})
            return

        # 读取请求数据
        content_len = int(self.headers.get("Content-Length", 0))
        raw_data = self.rfile.read(content_len) if content_len > 0 else b""
        if not raw_data:
            self._send_resp(400, {"status": "failed", "msg": "Empty request body"})
            return

        # 解析边界符并处理文件
        boundary = f"--{self.headers['Content-Type'].split('boundary=')[1]}".encode("utf-8")
        for segment in raw_data.split(boundary):
            if not segment.strip() or segment.endswith(b"--"):
                continue

            # 拆分头部和内容
            header, content = segment.split(b"\r\n\r\n", 1)
            # 提取文件名
            filename = self._get_filename(header)
            if not filename:
                continue

            # 核心：通过translate_path获取写入路径
            output_path = self.translate_path(self.path)
            # 路径处理：目录则拼接文件名，文件则直接使用
            if os.path.isdir(output_path) or not os.path.splitext(output_path)[1]:
                output_path = os.path.join(output_path, os.path.basename(filename))
            
            # 确保目录存在并写入文件（测试场景简化，仅基础异常）
            os.makedirs(os.path.dirname(output_path), exist_ok=True)
            with open(output_path, "wb") as f:
                f.write(content.rstrip(b"\r\n--"))

            # 返回成功响应
            self._send_resp(200, {
                "status": "success",
                "filename": filename,
                "save_path": output_path,
                "size": len(content.rstrip(b"\r\n--"))
            })
            return

        # 未找到文件
        self._send_resp(400, {"status": "failed", "msg": "No file found in request"})

    def _get_filename(self, header_bytes):
        """极简版文件名提取"""
        header_str = header_bytes.decode("utf-8", errors="ignore")
        for line in header_str.split("\r\n"):
            if "filename=" in line.lower():
                filename = line.split("filename=")[-1].strip('"\' ')
                return filename if filename else None
        return None

    def _send_resp(self, code, data):
        """极简响应发送"""
        resp = json.dumps(data).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(resp)))
        self.end_headers()
        self.wfile.write(resp)

if __name__ == "__main__":
    https = HTTPServer(("0.0.0.0", 8443), FileServer)
    sslcontext = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    filePath = os.path.dirname(os.path.abspath(__file__))
    projectDir = os.path.realpath(filePath + "/../../../..")
    testDataDir = os.path.realpath(
        projectDir + "/test/unit/test_data"
    )
    keyPath = os.path.realpath(filePath + "/data/key.pem")
    certPath = os.path.realpath(filePath + "/data/cert.pem")
    os.chdir(testDataDir)
    sslcontext.load_cert_chain(
        keyfile=keyPath,
        certfile=certPath,
        password="123456",
    )
    https.socket = sslcontext.wrap_socket(https.socket, server_side=True)
    logging.info("start run https service: https://127.0.0.1:8443/")
    https_server = https

    https.serve_forever()
