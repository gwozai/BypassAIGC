#!/bin/bash
# 清理脚本 - 用于重置环境或清理临时文件

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "\n${CYAN}========================================${NC}"
echo -e "${CYAN}BypassAIGC 清理工具${NC}"
echo -e "${CYAN}========================================${NC}\n"

echo -e "${YELLOW}选择清理选项:${NC}\n"
echo "1) 清理临时文件和日志"
echo "2) 停止所有服务"
echo "3) 删除数据库（保留配置）"
echo "4) 完全重置（删除虚拟环境和依赖）"
echo "5) 清理编译文件和缓存"
echo "0) 退出"
echo ""

read -p "请选择 [0-5]: " choice

case $choice in
    1)
        echo -e "\n${YELLOW}清理临时文件和日志...${NC}"
        
        # 清理日志文件
        rm -f "$SCRIPT_DIR/backend/backend.log" 2>/dev/null && echo "✓ 删除后端日志"
        rm -f "$SCRIPT_DIR/frontend/frontend.log" 2>/dev/null && echo "✓ 删除前端日志"
        rm -f "$SCRIPT_DIR/backend.log" 2>/dev/null
        rm -f "$SCRIPT_DIR/frontend.log" 2>/dev/null
        
        # 清理 PID 文件
        rm -f "$SCRIPT_DIR/backend.pid" 2>/dev/null && echo "✓ 删除 backend.pid"
        rm -f "$SCRIPT_DIR/frontend.pid" 2>/dev/null && echo "✓ 删除 frontend.pid"
        
        # 清理临时文件
        rm -rf "$SCRIPT_DIR/tmp" 2>/dev/null && echo "✓ 删除 tmp 目录"
        rm -rf "$SCRIPT_DIR/temp" 2>/dev/null
        
        echo -e "\n${GREEN}✓ 临时文件清理完成${NC}\n"
        ;;
    
    2)
        echo -e "\n${YELLOW}停止所有服务...${NC}"
        "$SCRIPT_DIR/stop-all.sh"
        ;;
    
    3)
        echo -e "\n${RED}警告: 这将删除数据库文件!${NC}"
        read -p "确认删除数据库? (yes/no): " confirm
        
        if [ "$confirm" = "yes" ]; then
            rm -f "$SCRIPT_DIR/backend/ai_polish.db" 2>/dev/null && echo "✓ 删除数据库文件"
            rm -f "$SCRIPT_DIR/backend/ai_polish.db-journal" 2>/dev/null
            echo -e "\n${GREEN}✓ 数据库已删除${NC}"
            echo -e "${CYAN}下次启动时将自动创建新数据库${NC}\n"
        else
            echo -e "${YELLOW}已取消${NC}\n"
        fi
        ;;
    
    4)
        echo -e "\n${RED}警告: 这将删除所有虚拟环境和依赖!${NC}"
        echo -e "${RED}您需要重新运行 ./setup.sh${NC}"
        read -p "确认完全重置? (yes/no): " confirm
        
        if [ "$confirm" = "yes" ]; then
            # 先停止服务
            "$SCRIPT_DIR/stop-all.sh" 2>/dev/null
            
            # 删除后端环境
            echo -e "\n${YELLOW}删除后端虚拟环境...${NC}"
            rm -rf "$SCRIPT_DIR/backend/venv" && echo "✓ 删除 backend/venv"
            rm -rf "$SCRIPT_DIR/backend/__pycache__" 2>/dev/null
            find "$SCRIPT_DIR/backend" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
            find "$SCRIPT_DIR/backend" -type f -name "*.pyc" -delete 2>/dev/null
            
            # 删除前端依赖
            echo -e "${YELLOW}删除前端依赖...${NC}"
            rm -rf "$SCRIPT_DIR/frontend/node_modules" && echo "✓ 删除 frontend/node_modules"
            rm -rf "$SCRIPT_DIR/frontend/dist" 2>/dev/null
            rm -rf "$SCRIPT_DIR/frontend/build" 2>/dev/null
            rm -rf "$SCRIPT_DIR/frontend/.next" 2>/dev/null
            
            # 清理临时文件
            rm -f "$SCRIPT_DIR"/*.log 2>/dev/null
            rm -f "$SCRIPT_DIR"/*.pid 2>/dev/null
            
            echo -e "\n${GREEN}✓ 环境重置完成${NC}"
            echo -e "${CYAN}请运行 ./setup.sh 重新配置环境${NC}\n"
        else
            echo -e "${YELLOW}已取消${NC}\n"
        fi
        ;;
    
    5)
        echo -e "\n${YELLOW}清理编译文件和缓存...${NC}"
        
        # Python 缓存
        find "$SCRIPT_DIR/backend" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null && echo "✓ 清理 Python 缓存"
        find "$SCRIPT_DIR/backend" -type f -name "*.pyc" -delete 2>/dev/null
        find "$SCRIPT_DIR/backend" -type f -name "*.pyo" -delete 2>/dev/null
        
        # Node 缓存
        rm -rf "$SCRIPT_DIR/frontend/.next" 2>/dev/null && echo "✓ 清理 Next.js 缓存"
        rm -rf "$SCRIPT_DIR/frontend/dist" 2>/dev/null && echo "✓ 清理构建文件"
        rm -rf "$SCRIPT_DIR/frontend/build" 2>/dev/null
        
        echo -e "\n${GREEN}✓ 缓存清理完成${NC}\n"
        ;;
    
    0)
        echo -e "\n${CYAN}已退出${NC}\n"
        exit 0
        ;;
    
    *)
        echo -e "\n${RED}无效选项${NC}\n"
        exit 1
        ;;
esac
