#!/bin/bash
# 一键启动脚本 - macOS 版本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "\n${CYAN}========================================${NC}"
echo -e "${CYAN}AI 学术写作助手 - 启动中 (macOS)${NC}"
echo -e "${CYAN}========================================${NC}\n"

# 检查操作系统
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}× 此脚本仅适用于 macOS${NC}"
    echo -e "${YELLOW}Linux/Ubuntu 请使用: ./start-all.sh${NC}\n"
    exit 1
fi

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 检查是否安装了 tmux
if command -v tmux &> /dev/null; then
    USE_TMUX=true
    echo -e "${CYAN}检测到 tmux，将使用 tmux 启动服务${NC}"
else
    echo -e "${YELLOW}未检测到 tmux，建议安装以便后台运行${NC}"
    echo -e "${CYAN}安装命令: ${YELLOW}brew install tmux${NC}"
    echo -e "${CYAN}将使用普通方式启动（需要保持终端窗口打开）${NC}\n"
    
    read -p "是否继续? (y/n): " continue_choice
    if [ "$continue_choice" != "y" ] && [ "$continue_choice" != "Y" ]; then
        echo -e "${YELLOW}已取消${NC}\n"
        exit 0
    fi
fi

# 检查依赖
echo -e "\n${YELLOW}[1/3] 检查环境...${NC}"

if [ ! -d "$SCRIPT_DIR/backend/venv" ]; then
    echo -e "${RED}× 后端虚拟环境不存在${NC}"
    echo -e "${YELLOW}请先运行: ./setup-macos.sh${NC}\n"
    exit 1
fi

if [ ! -d "$SCRIPT_DIR/frontend/node_modules" ]; then
    echo -e "${RED}× 前端依赖未安装${NC}"
    echo -e "${YELLOW}请先运行: ./setup-macos.sh${NC}\n"
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/backend/.env" ]; then
    echo -e "${RED}× 配置文件不存在${NC}"
    echo -e "${YELLOW}请先运行: ./setup-macos.sh${NC}\n"
    exit 1
fi

echo -e "${GREEN}✓ 环境检查通过${NC}\n"

# 启动后端
echo -e "${YELLOW}[2/3] 启动后端服务...${NC}"

if [ "$USE_TMUX" = true ]; then
    # 使用 tmux
    tmux new-session -d -s bypassaigc-backend "cd '$SCRIPT_DIR/backend' && source venv/bin/activate && uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"
    echo -e "${GREEN}✓ 后端服务已在 tmux 会话 'bypassaigc-backend' 中启动${NC}"
    echo -e "${CYAN}  查看后端: tmux attach -t bypassaigc-backend${NC}"
    echo -e "${CYAN}  退出会话: Cmd+B 然后按 D${NC}"
else
    # 没有 tmux，在后台运行
    cd "$SCRIPT_DIR/backend"
    source venv/bin/activate
    nohup uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload > backend.log 2>&1 &
    BACKEND_PID=$!
    echo $BACKEND_PID > "$SCRIPT_DIR/backend.pid"
    deactivate
    echo -e "${GREEN}✓ 后端服务已启动 (PID: $BACKEND_PID)${NC}"
    echo -e "${CYAN}  查看日志: tail -f backend/backend.log${NC}"
    cd "$SCRIPT_DIR"
fi

# 等待后端启动
echo -e "${CYAN}等待后端服务启动...${NC}"
sleep 5

# 检查后端是否成功启动
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ 后端服务启动成功${NC}\n"
else
    echo -e "${YELLOW}⚠ 无法连接到后端服务，但进程已启动${NC}"
    echo -e "${YELLOW}  请稍后访问: http://localhost:8000/docs${NC}\n"
fi

# 启动前端
echo -e "${YELLOW}[3/3] 启动前端服务...${NC}"

if [ "$USE_TMUX" = true ]; then
    # 使用 tmux
    tmux new-session -d -s bypassaigc-frontend "cd '$SCRIPT_DIR/frontend' && npm run dev"
    echo -e "${GREEN}✓ 前端服务已在 tmux 会话 'bypassaigc-frontend' 中启动${NC}"
    echo -e "${CYAN}  查看前端: tmux attach -t bypassaigc-frontend${NC}"
else
    # 没有 tmux，在后台运行
    cd "$SCRIPT_DIR/frontend"
    nohup npm run dev > frontend.log 2>&1 &
    FRONTEND_PID=$!
    echo $FRONTEND_PID > "$SCRIPT_DIR/frontend.pid"
    echo -e "${GREEN}✓ 前端服务已启动 (PID: $FRONTEND_PID)${NC}"
    echo -e "${CYAN}  查看日志: tail -f frontend/frontend.log${NC}"
    cd "$SCRIPT_DIR"
fi

# 完成
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}✓ 系统启动完成!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${CYAN}访问地址:${NC}"
echo -e "  前端: ${YELLOW}http://localhost:3000${NC}"
echo -e "  后端: ${YELLOW}http://localhost:8000${NC}"
echo -e "  管理: ${YELLOW}http://localhost:3000/admin${NC}"
echo -e "  文档: ${YELLOW}http://localhost:8000/docs${NC}"
echo -e "${GREEN}========================================${NC}\n"

if [ "$USE_TMUX" = true ]; then
    echo -e "${CYAN}管理 tmux 会话:${NC}"
    echo -e "  查看所有: ${YELLOW}tmux ls${NC}"
    echo -e "  进入后端: ${YELLOW}tmux attach -t bypassaigc-backend${NC}"
    echo -e "  进入前端: ${YELLOW}tmux attach -t bypassaigc-frontend${NC}"
    echo -e "  退出会话: ${YELLOW}Cmd+B 然后按 D${NC}"
    echo -e "  停止服务: ${YELLOW}tmux kill-session -t bypassaigc-backend${NC}"
    echo -e "            ${YELLOW}tmux kill-session -t bypassaigc-frontend${NC}"
    echo -e "\n${CYAN}或使用停止脚本:${NC}"
    echo -e "  ${YELLOW}./stop-all.sh${NC}\n"
else
    echo -e "${CYAN}停止服务:${NC}"
    echo -e "  停止后端: ${YELLOW}kill \$(cat backend.pid)${NC}"
    echo -e "  停止前端: ${YELLOW}kill \$(cat frontend.pid)${NC}"
    echo -e "  或使用: ${YELLOW}./stop-all.sh${NC}\n"
fi

echo -e "${CYAN}macOS 提示:${NC}"
echo -e "  • 浏览器将自动打开前端页面"
echo -e "  • 使用 ${YELLOW}Activity Monitor${NC} 查看进程状态"
echo -e "  • 日志位置: backend/backend.log 和 frontend/frontend.log\n"

# 尝试在默认浏览器中打开
sleep 2
if command -v open &> /dev/null; then
    echo -e "${CYAN}正在打开浏览器...${NC}"
    open http://localhost:3000
fi
