#!/bin/bash
# Деплой сайта ГБПОУ РО «Сальский индустриальный техникум» — https://сит-сальск.рф
#
# Источник кода: git@github.com:DimaNikolaevi4/cit-calck.rf.git, ветка main.
# Запуск на сервере: cd ~/sit-saljsk.rf && bash deploy.sh
#
# ВАЖНО: часть файлов живёт ТОЛЬКО на хостинге и в репозитории их нет намеренно:
#   public_html/docs/       — 291 документ (лицензия, рабочие программы, локальные акты), 1,2 ГБ
#   public_html/uploads/    — файлы, загруженные через формы сайта
#   public_html/submit-form.php, forms.log, .htaccess
# Они исключены из очистки ниже — не убирайте эти исключения, иначе при деплое
# документы будут удалены с сайта и восстановить их будет неоткуда.
set -e

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
NC=$'\033[0m'

log_info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

PROJECT_DIR="$HOME/sit-saljsk.rf"
NVM_DIR="$HOME/.nvm"
BUILD_DIR="$PROJECT_DIR/temp-build"
REPO_URL="git@github.com:DimaNikolaevi4/cit-calck.rf.git"
REPO_BRANCH="main"

ensure_node() {
    if command -v node &>/dev/null && command -v npm &>/dev/null; then
        log_info "Node.js $(node -v) готов."
        return 0
    fi
    log_warn "Устанавливаем Node.js через NVM..."
    if [ ! -s "$NVM_DIR/nvm.sh" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    fi
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    if ! command -v node &>/dev/null; then
        nvm install --lts
        nvm use --lts
        nvm alias default 'lts/*'
    fi
    log_info "Node.js $(node -v) готов."
}

run_deploy() {
    log_info "Начало деплоя..."
    cd "$PROJECT_DIR" || { log_error "Нет папки $PROJECT_DIR"; exit 1; }

    # === Обновление рабочей копии репозитория ===
    if [ -d "$BUILD_DIR/.git" ]; then
        log_info "Обновляем существующий репозиторий (git fetch)..."
        cd "$BUILD_DIR"
        GIT_SSH_COMMAND="ssh -i ~/.ssh/github -o IdentitiesOnly=yes" \
            git fetch origin "$REPO_BRANCH"
        GIT_SSH_COMMAND="ssh -i ~/.ssh/github -o IdentitiesOnly=yes" \
            git reset --hard "origin/$REPO_BRANCH"
        GIT_SSH_COMMAND="ssh -i ~/.ssh/github -o IdentitiesOnly=yes" \
            git clean -fd
    else
        log_info "Клонируем репозиторий (первый запуск)..."
        GIT_SSH_COMMAND="ssh -i ~/.ssh/github -o IdentitiesOnly=yes" \
            git clone --branch "$REPO_BRANCH" "$REPO_URL" "$BUILD_DIR"
        cd "$BUILD_DIR"
    fi

    # === Зависимости ===
    # npm ci --omit=dev ставит только прод-зависимости (быстро), но для сборки
    # нужны devDependencies (@11ty/eleventy, sharp, clean-css). Следующая строка
    # с npm install доустанавливает полное дерево, включая их.
    log_info "Устанавливаем зависимости..."
    npm ci --omit=dev
    npm install js-yaml 2>/dev/null || true

    # === Сборка ===
    log_info "Собираем проект (build:v2)..."
    npm run build:v2

    # === Копирование в public_html ===
    log_info "Очищаем public_html (кроме данных, которые живут только на хостинге)..."
    cd "$PROJECT_DIR/public_html"
    find . -mindepth 1 -maxdepth 1 \
        ! -name "docs" \
        ! -name "uploads" \
        ! -name "submit-form.php" \
        ! -name "forms.log" \
        ! -name ".htaccess" \
        -exec rm -rf {} +

    log_info "Копируем файлы из public-v2..."
    cp -r "$BUILD_DIR/public-v2/"* "$PROJECT_DIR/public_html/"

    if [ -f "$BUILD_DIR/submit-form.php" ]; then
        cp "$BUILD_DIR/submit-form.php" "$PROJECT_DIR/public_html/"
    fi

    if [ -f "$PROJECT_DIR/public_html/robots/index.html" ]; then
        mv "$PROJECT_DIR/public_html/robots/index.html" "$PROJECT_DIR/public_html/robots.txt"
        rmdir "$PROJECT_DIR/public_html/robots" 2>/dev/null || true
    fi

    log_info "Устанавливаем права..."
    find "$PROJECT_DIR/public_html" -type f \( \
        -name "*.html" -o -name "*.css" -o -name "*.js" -o \
        -name "*.xml" -o -name "*.txt" -o -name "*.php" \) \
        -exec chmod 644 {} \;
    find "$PROJECT_DIR/public_html" -type d -exec chmod 755 {} \;
    chmod 777 "$PROJECT_DIR/public_html/uploads/forms" 2>/dev/null || true

    # temp-build не удаляем — следующий деплой обновится через git fetch.
    log_info "Деплой завершён! Сайт: https://сит-сальск.рф"
}

ensure_node
run_deploy
