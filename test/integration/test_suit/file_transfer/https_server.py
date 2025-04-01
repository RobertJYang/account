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
from io import BytesIO
import re
import os
import ssl
from http.server import HTTPServer, SimpleHTTPRequestHandler


class FileServer(SimpleHTTPRequestHandler):
    def do_POST(self):
        ret, info = self.deal_post_data()
        logging.info((ret, info, "by: ", self.client_address))
        file = BytesIO()
        file.write(b'<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">')
        file.write(b"<html>\n<title>Upload Result Page</title>\n")
        file.write(b"<body>\n<h2>Upload Result Page</h2>\n")
        file.write(b"<hr>\n")
        if ret:
            file.write(b"<strong>Success:</strong>")
        else:
            file.write(b"<strong>Failed:</strong>")
        file.write(info.encode())
        file.write(('<br><a href="%s">back</a>' % self.headers["referer"]).encode())
        file.write(b"</body>\n</html>\n")
        length = file.tell()
        file.seek(0)
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.send_header("Content-Length", str(length))
        self.end_headers()
        self.copyfile(file, self.wfile)
        file.close()

    def deal_post_data(self):
        content_type = self.headers["content-type"]
        if not content_type:
            return (False, "Content-Type header doesn't contain boundary")
        boundary = content_type.split("=")[1].encode()
        remain_bytes = int(self.headers["content-length"])
        line = self.rfile.readline()
        remain_bytes -= len(line)
        if boundary not in line:
            return (False, "Content NOT begin with boundary")
        line = self.rfile.readline()
        remain_bytes -= len(line)
        find = re.findall(
            r'Content-Disposition.*name="file"; filename="(.*)"', line.decode()
        )
        if not find:
            return (False, "Can't find out file name...")
        path = self.translate_path(self.path)
        line = self.rfile.readline()
        remain_bytes -= len(line)
        line = self.rfile.readline()
        remain_bytes -= len(line)
        try:
            out = open(path, "wb")
        except IOError:
            return (
                False,
                "Can't create file to write, do you have permission to write?",
            )

        rfile_line = self.rfile.readline()
        remain_bytes -= len(rfile_line)
        while remain_bytes > 0:
            line = self.rfile.readline()
            remain_bytes -= len(line)
            if boundary in line:
                rfile_line = rfile_line[0:-1]
                if rfile_line.endswith(b"\r"):
                    rfile_line = rfile_line[0:-1]
                out.write(rfile_line)
                out.close()
                return (True, "File '%s' upload success!" % find)
            else:
                out.write(rfile_line)
                rfile_line = line
        return (False, "Unexpect Ends of data.")


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
