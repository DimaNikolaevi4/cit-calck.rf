# Сайт ГБПОУ РО «Сальский индустриальный техникум»

Официальный сайт: https://сит-сальск.рф/

## Технологии

- **Eleventy 3** — генератор статических сайтов
- **Bootstrap 5** — CSS-фреймворк
- **Nunjucks** — шаблонизатор
- **Lunr.js** — полнотекстовый поиск
- **AOS** — анимации появления
- **GLightbox** — просмотр изображений

## Сборка

```bash
npm ci
npm run build:v2
```

Результат — в папке `public-v2/`.

## Деплой

Деплой на хостинг Beget через `deploy.sh`:

```bash
cd ~/sit-saljsk.rf
bash deploy.sh
```

## CI проверки

```bash
npm run check:frontmatter
npm run check:urls:unique
npm run check:urls:generated:v2
npm run check:links:v2
npm run check:route-shape:v2
```

## Структура

```
src/
├── _data/          # Глобальные данные (menu, rubrics, contacts, etc.)
├── _filters/       # Фильтры Nunjucks
├── _includes/       # Шаблоны и компоненты
│   ├── components/  # header, hero, news, popular, sidebar, footer
│   └── layouts/    # base, page, page-full, post, listing
├── assets/         # Картинки, JS, фавиконы
├── content/        # Markdown-страницы
├── pages/          # Шаблоны страниц (news-list, search, tags, 404)
├── styles/         # CSS (main.css, critical.css)
└── index.njk       # Главная страница
```
