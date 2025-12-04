项目环境速览与与智能体交互提示词 (envprompt)

目的：为将来与智能体（例如代码助理、自动化脚本或CI机器人）交互时提供一个简明的项目环境说明和常用提示词清单，方便快速定位、运行、调试与开发。

一、项目整体说明

- 前端 (Flutter)：位于 `web/` 目录，使用 Flutter 框架构建，包含常见 Flutter 项目结构（`lib/`、`android/`、`ios/`、`windows/` 等）。README 简短说明这是一个标准的 Flutter 起始项目，参见官方文档进行开发与调试。
- 后端 (Django)：位于 `backend/` 目录，采用 Django 5.0 + Django REST Framework，推荐 Python 3.11。支持 SQLite（默认，便于本地开发）或 MariaDB/MySQL（生产/更大负载）。

二、重要文件与目录（快速导航）

- 根目录
  - `envprompt.md`：本文件。
- web/
  - `lib/`：Flutter 源代码，主入口为 `lib/main.dart`。
  - `pubspec.yaml` / `pubspec.lock`：Flutter 包依赖与版本。
  - 平台目录：`android/`、`ios/`、`macos/`、`windows/`、`linux/` 等。
  - `test/`：Flutter 测试（如 `widget_test.dart`）。
- backend/
  - `manage.py`：Django 管理脚本。
  - `requirements.txt`：Python 依赖。
  - `.env.example`：环境变量示例（复制为 `.env` 并填入实际值）。
  - `mentor_platform/`：Django 项目配置（`settings.py`、`urls.py`、`wsgi.py` 等）。
  - 应用目录：`users/`、`courses/`、`progress/`、`authentication/`（每个包含 `models.py`、`views.py`、`admin.py`、`migrations/` 等）。

三、快速启动（本地开发）

后端（Django）建议步骤（已在 `backend/README.md` 中）：
1. 创建并激活 Python 虚拟环境（示例使用 conda）：
   - conda: `conda create -n mentor-backend python=3.11 -y; conda activate mentor-backend`
2. 安装依赖：`pip install -r requirements.txt`（可使用国内镜像 `-i https://pypi.tuna.tsinghua.edu.cn/simple`）。
3. 复制环境文件并配置：`cp .env.example .env`，编辑 `.env` 填写数据库与密钥等。
4. 数据库迁移：`python manage.py makemigrations; python manage.py migrate`。
5. 创建超级用户：`python manage.py createsuperuser`。
6. 启动开发服务器：`python manage.py runserver`（访问 http://127.0.0.1:8000 和 http://127.0.0.1:8000/admin/）。

前端（Flutter）建议步骤：
1. 安装 Flutter SDK 并确保 `flutter doctor` 通过。
2. 在 `web/` 目录运行：`flutter pub get` 安装依赖。
3. 运行项目（Web/移动/桌面按需）：例如 `flutter run -d chrome` 或针对平台的运行命令。

四、已知注意事项与建议

- CORS：在生产/多个来源开发时，需要配置后端的 CORS 设置以允许前端访问 API。
- SECRET_KEY 与 DEBUG：生产环境请确保在 `.env` 中设置安全的 `SECRET_KEY` 并将 `DEBUG=False`。
- 时区与本地化：后端建议使用 `Asia/Shanghai`（hans 如需汉化），确保时间显示一致。
- 数据库：开发可用 SQLite，生产建议 MariaDB/MySQL，并在 `.env` 中配置连接字符串。

五、与智能体交互时可用的基础提示词（模板）

下面的提示词可直接用于向智能体说明需求，或作为提问模板：

- 项目结构与导航
  - “请快速列出该仓库中 `backend/` 的关键文件和它们的职责。”
  - “我需要在 `web/lib/` 找到应用入口并说明如何启动前端。”

- 本地运行与设置
  - “帮我写出一份用于 Windows 的逐步本地运行手册，从安装依赖到启动后端和前端。”
  - “如何把后端从 SQLite 切换到 MariaDB，并给出 `settings.py` 与 `.env` 的示例配置？”

- 开发帮助（实现/调试）
  - “后端报错：<在此粘贴错误堆栈>，请帮我定位可能原因和修复步骤。”
  - “我想新增一个 API：创建课程（title, description），请生成 Django model、serializer、view 与 URL 配置的最小实现。”

- 安全与部署
  - “请列出部署到生产时需要完成的安全检查清单（Django）。并给出一个简单的 `systemd` 服务文件和 Nginx 反向代理示例。”

- 测试与质量保证
  - “为 `courses` 应用写一个包含模型和视图的基本单元测试集（pytest / Django test），并说明如何运行它们。”

六、联系人与下一步建议

- 如果你是新加入者：先在本地跑通后端与前端，再阅读 `backend/` 中的每个 app（`users`, `courses`, `progress`, `authentication`）的 `models.py` 与 `views.py`。
- 建议后续工作：添加 `README.md` 到每个子应用，编写 CI 流程（例如 GitHub Actions）来运行后端测试与 Flutter 的静态检查。

——

（本文件由智能体根据 `backend/README.md` 与 `web/README.md` 自动生成，供日后与智能体交互时使用。）
