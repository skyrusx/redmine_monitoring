# Redmine Monitoring

Текущая версия: `0.2.4`

Плагин для Redmine, который перехватывает все ошибки приложения (включая HTTP-ошибки), метрики запросов и рекомендации
по оптимизации (Bullet), сохраняет их в базу и предоставляет удобный интерфейс для просмотра.

## Возможности

- **Глобальный перехват ошибок** через middleware:
    - исключения (`StandardError`, `RuntimeError`, `ActiveRecord::RecordInvalid` и т.п.);
    - HTTP-статусы.
- **Сохранение информации** в таблицу `monitoring_errors`:
    - класс и сообщение ошибки;
    - backtrace;
    - контроллер/действие (`ProjectsController#index`);
    - статус ответа (`500`, `404` и др.);
    - пользователь (если авторизован);
    - параметры запроса (`params`);
    - заголовки (`headers`);
    - окружение (`Rails.env`);
    - IP, User-Agent, Referer.
- **Группировка ошибок**:
    - объединение однотипных ошибок в группы;
    - быстрый просмотр количества повторений;
    - фильтрация по классам ошибок, контроллерам, статусам и пользователям.
- **Метрики запросов**:
    - логирование всех входящих запросов;
    - метод, путь, формат, статус;
    - время выполнения (total/db/view);
    - размер ответа (`bytes_sent`);
    - связанный пользователь и IP.
- **Рекомендации (Bullet integration)**:
    - автоматическое сохранение подсказок Bullet (N+1, unused eager loading, counter cache);
    - привязка к запросу, контроллеру, пользователю;
    - удобный просмотр в отдельной вкладке.
- **UI в админке Redmine**:
    - вкладки: dashboard, ошибки, метрики, группы ошибок, рекомендации, алерты, security;
    - список с пагинацией и фильтрами (по пользователю, контроллеру, статусу и др.);
    - раскрытие деталей по клику;
    - подсветка и форматирование JSON (params, headers);
    - кнопка «копировать» для сниппетов.
- **Экспорт данных**:
    - CSV;
    - JSON;
    - PDF;
    - XLSX.
- **Алерты**:
    - группировка однотипных ошибок;
    - отправка уведомлений по email и Telegram;
    - ограничение частоты уведомлений.
- **Security scan**:
    - запуск Brakeman через API или CLI;
    - сохранение результатов сканирования;
    - просмотр HTML-отчёта, если включено хранение отчётов.
- **Кнопки действий**:
    - «Создать тестовую ошибку»;
    - «Создать тестовую рекомендацию» (для Bullet);
    - «Создать тестовый алерт»;
    - «Запустить security scan»;
    - «Очистить» (для ошибок, метрик, рекомендаций).
- **Настройки плагина**:
    - включение/выключение мониторинга;
    - режим разработки (включает Bullet-интеграцию и тестовые кнопки);
    - ограничения хранения ошибок, метрик, рекомендаций и security scan;
    - маскирование и лимиты сохраняемых данных;
    - каналы уведомлений;
    - настройки security scan.

---

## Установка

1. Клонируйте репозиторий в каталог `plugins` Redmine:

   ```bash
   cd redmine/plugins
   git clone https://github.com/skyrusx/redmine_monitoring.git
   ```

2. Выполните миграции:

   ```bash
   bundle exec rake redmine:plugins:migrate
   ```

3. Перезапустите Redmine.

4. Если нужны Bullet-рекомендации, установите `bullet` в окружение Redmine и включите `dev_mode`,
   `enable_recommendations` и `enable_bullet_recommendations` в настройках плагина.

---

## Использование

- Перейдите в меню **Администрирование → Плагины → Redmine Monitoring plugin**.
- Включите мониторинг в настройках.
- Откройте страницу `/monitoring`, чтобы увидеть список ошибок.
- Используйте кнопку «Создать тестовую ошибку» для проверки.

---

## Эксплуатация

На вкладке `dashboard` есть блок состояния плагина. Он показывает включённые модули, доступность Bullet,
количество записей в основных таблицах, последние события и диагностику уведомлений. В диагностике видно,
какие каналы активны, настроены ли email/Telegram, какой был последний статус доставки и последняя ошибка.

### Cleanup tasks

Для ручной или плановой очистки накопленных данных доступны rake tasks:

```bash
bundle exec rake redmine_monitoring:cleanup:errors RAILS_ENV=production
bundle exec rake redmine_monitoring:cleanup:metrics RAILS_ENV=production
bundle exec rake redmine_monitoring:cleanup:recommendations RAILS_ENV=production
bundle exec rake redmine_monitoring:cleanup:security RAILS_ENV=production
bundle exec rake redmine_monitoring:cleanup:all RAILS_ENV=production
```

Параметры:

- `DRY_RUN=1` — показать, что будет удалено, без удаления.
- `DAYS=30` — переопределить retention для одного запуска.
- `BATCH=1000` — размер батча удаления.
- `VERBOSE=1` — добавить разделение вывода между целями.

Примеры:

```bash
bundle exec rake redmine_monitoring:cleanup:all DRY_RUN=1 RAILS_ENV=production
bundle exec rake redmine_monitoring:cleanup:errors DAYS=14 BATCH=500 RAILS_ENV=production
```

Пример cron:

```cron
0 3 * * * cd /opt/redmine && bundle exec rake redmine_monitoring:cleanup:all RAILS_ENV=production
```

### Operational logs

Плагин пишет эксплуатационные и диагностические сообщения в отдельный общий файл:

```text
log/redmine_monitoring.log
```

Сообщения operational logging идут с префиксом `[Monitoring][ops]`. Они помогают понять,
почему модуль не работает или был пропущен:

- middleware/request subscriber/Bullet attach;
- monitoring или metrics отключены настройками;
- Bullet недоступен или отключён настройками;
- notifications отключены;
- email/Telegram включены, но настроены не полностью;
- ошибка доставки уведомления;
- выбранный режим Brakeman scan;
- отключено хранение HTML security-отчёта.

Частые диагностические сообщения логируются один раз за runtime процесса, чтобы не спамить логи на каждый запрос.

---

## API / Технические детали

- Middleware `RedmineMonitoring::Middleware` ловит ошибки.
- Контроллер `MonitoringErrorsController`:
    - `index` — список ошибок;
    - `test_error` — создание тестовой ошибки;
    - `clear` — очистка всех ошибок (POST).
    - `test_reco` — создание тестовой рекомендации;
- Модель `MonitoringError` хранит все данные об ошибке.
- Модель `MonitoringRecommendation` хранит все данные о рекомендациях.
- Модель `MonitoringRequest` хранит все данные о метриках запросов.

---

## Настройки (settings)

- `enabled` — включить/выключить мониторинг (по умолчанию `true`).
- `dev_mode` — режим разработки (по умолчанию `false`).
- `max_errors` — максимальное количество ошибок, хранимых в базе (старые автоматически удаляются).
- `retention_days` — срок хранения ошибок в днях.
- `log_levels` — уровни логирования, которые будут сохраняться (например: `error`, `warning` и т. д.).
- `enabled_formats` — список форматов, для которых включён мониторинг (`html`, `json`, `xml` и т. д.).
- `enable_metrics` — включение сбора метрик запросов.
- `slow_request_threshold_ms` — порог (в миллисекундах) для пометки запроса как «медленного».
- `metrics_max_records` — максимальное количество записей метрик.
- `metrics_retention_days` — срок хранения метрик.
- `recommendations_retention_days` — срок хранения рекомендаций.
- `security_retention_days` — срок хранения результатов security scan.
- `mask_sensitive_data` — маскировать чувствительные значения в params и headers.
- `sensitive_keys` — список ключей для маскирования (`password`, `token`, `authorization`, `cookie`, `secret`, `api_key`).
- `capture_headers` — сохранять или не сохранять request headers.
- `capture_env` — сохранять или не сохранять окружение записи.
- `params_max_bytes` — максимальный размер сохраняемых params.
- `headers_max_bytes` — максимальный размер сохраняемых headers.
- `env_max_bytes` — максимальный размер сохраняемого env.
- `backtrace_max_bytes` — максимальный размер сохраняемого backtrace.
- `notify_enabled` — включение уведомлений.
- `notify_channels` — каналы уведомлений (`email`, `telegram`).
- `notify_severity_min` — минимальный уровень ошибки для уведомлений.
- `notify_formats` — форматы запросов, по которым отправляются уведомления.
- `notify_email_recipients` — получатели email-уведомлений.
- `notify_telegram_bot_token` — токен Telegram-бота.
- `notify_telegram_chat_ids` — список Telegram chat id.
- `security_enabled` — включение security-раздела.
- `security_allow_manual_scan` — разрешение ручного запуска security scan.
- `security_keep_html` — хранение HTML-отчёта Brakeman.

---

## Данные и аудит

Плагин сохраняет технические данные, необходимые для диагностики: класс и сообщение ошибки, backtrace,
controller/action, HTTP-статус, формат, пользователя, IP, User-Agent, Referer, params, выбранные headers,
Rails environment, request metrics, Bullet-рекомендации, алерты и результаты Brakeman security scan.

Для снижения риска утечки секретов включено маскирование sensitive keys. По умолчанию маскируются ключи,
содержащие `password`, `token`, `authorization`, `cookie`, `secret`, `api_key`. Значение заменяется на
`[FILTERED]`. Размеры `params`, `headers`, `env` и `backtrace` ограничиваются настройками. Headers и env
можно полностью отключить в настройках плагина.

---

## Изменения 0.2.4

- Добавлен `RedmineMonitoring::OperationalLogger`.
- Добавлены startup/attach logs для middleware, request subscriber и Bullet.
- Добавлены logs для отключённых metrics/monitoring/Bullet/notifications.
- Добавлены logs для неполной настройки email/Telegram и ошибок доставки.
- Добавлены logs для Brakeman mode и отключённого HTML storage.
- Добавлено once-логирование для частых diagnostic branches.
- Operational logs и middleware/error reporter logs переведены в `log/redmine_monitoring.log`.

## Изменения 0.2.3

- Добавлен `MonitoringErrors::Cleanup`.
- Добавлены rake tasks для cleanup errors, metrics, recommendations, security и all.
- Добавлены параметры `DRY_RUN`, `DAYS`, `BATCH`, `VERBOSE`.
- Cleanup удаляет данные батчами и выводит matched/deleted/cutoff.
- README/CHANGELOG дополнены командами и cron-примером.

## Изменения 0.2.2

- Добавлен `MonitoringErrors::HealthStatus`.
- Добавлен health/status блок на dashboard.
- Добавлены counts по таблицам мониторинга.
- Добавлены latest records для ошибок, метрик, рекомендаций, доставок и security scan.
- Добавлена диагностика настроек email/Telegram уведомлений.
- README/CHANGELOG обновлены под эксплуатационный релиз.

## Изменения 0.2.1

- Адаптация плагина под Redmine 4.2.

## Изменения 0.2.0

- Добавлено маскирование sensitive data в params и headers.
- Добавлены лимиты размера для params, headers, env и backtrace.
- Добавлены настройки хранения/не хранения headers и env.
- Добавлен раздельный retention для errors, metrics, recommendations и security scan.
- `security_keep_html` теперь применяется при импорте Brakeman-отчёта.
- Добавлено audit-friendly описание сохраняемых данных.

## Изменения 0.1.5

- Добавлены регрессионные тесты для загрузки без Bullet, фильтров, retention, security report и notification dispatcher.
- Добавлен production-like smoke-тест для Bullet-интеграции.
- Добавлены проверки PostgreSQL/MySQL-совместимости миграций.
- Миграции переведены с PostgreSQL-only `jsonb` на переносимый `json`.
- Убраны database defaults у JSON-колонок для совместимости с MySQL.
- Security warning scopes переведены с PostgreSQL-only SQL на adapter-aware условия.
- Исправлен fallback чтения settings для метрик.
- Добавлен changelog.
- Рабочая директория очищена от локального IDE/macOS мусора.

## Изменения 0.1.4

- Исправлена загрузка плагина в окружениях без Bullet.
- Исправлена проверка HTML-отчёта security scan.
- Исправлена валидация `enabled_formats`.
- Убрана привязка email-получателей к конкретному домену.
- README обновлён под текущий набор возможностей.

---

## Совместимость

- Redmine 4.x / 5.x
- Ruby 2.6+
- PostgreSQL / MySQL

---

## Лицензия

[MIT](LICENSE.txt)
