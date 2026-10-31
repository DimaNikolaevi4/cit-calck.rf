# Деплой

Сайт: https://сит-сальск.рф/
Хостинг: Beget, статический сайт собирается на сервере скриптом `deploy.sh`.

## Как это работает

```
git@github.com:DimaNikolaevi4/cit-calck.rf.git (ветка main)
        |  git clone / git fetch + reset --hard
        v
~/sit-saljsk.rf/temp-build        — рабочая копия репозитория на сервере
        |  npm ci --omit=dev && npm install js-yaml && npm run build:v2
        v
~/sit-saljsk.rf/temp-build/public-v2
        |  копирование в public_html (старое содержимое удаляется, кроме исключений)
        v
~/sit-saljsk.rf/public_html        — то, что отдаётся посетителям
```

## Запуск

```bash
ssh localhost -p222          # docker-контейнер хостинга
cd ~/sit-saljsk.rf
bash deploy.sh
```

## Что живёт только на хостинге

Эти данные не хранятся в репозитории и исключены из очистки `public_html` в `deploy.sh`:

| Путь | Что это | Объём |
|---|---|---|
| `public_html/docs/` | 291 документ: лицензия, рабочие программы, локальные акты, положения | ~1,2 ГБ |
| `public_html/uploads/` | файлы, загруженные через формы сайта | — |
| `public_html/submit-form.php` | обработчик формы обратной связи | — |
| `public_html/forms.log`, `public_html/.htaccess` | журнал форм, конфигурация Apache | — |

**Внимание:** если убрать эти исключения из `deploy.sh`, при следующем деплое документы будут удалены с сайта. Восстановить их можно только из резервной копии хостинга — в git их нет.

Новый документ публикуется загрузкой файла в `public_html/docs/` (файловый менеджер Beget или SFTP), после чего на него можно ссылаться из контента.

## Проверки перед деплоем

CI на GitHub Actions (`.github/workflows/ci.yml`) запускается на каждый push и pull request в `main`:

```bash
npm ci
npm run build:v2
npm run check:frontmatter
npm run check:v2:source-boundary
npm run check:urls:unique
npm run check:urls:generated:v2
npm run check:links:v2
npm run check:route-shape:v2
```

Локально те же шаги можно выполнить вручную после `npm ci`.

## Откат

`git reset --hard <предыдущий коммит>` в `temp-build` и повторный запуск `deploy.sh` — сервер собирает то, что лежит в `origin/main`.