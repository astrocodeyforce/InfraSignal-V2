#!/usr/bin/env python3
"""
Russian translation for InfraSignal - Complete .po translation using polib.
Translates all untranslated entries, fixes fuzzy entries, and adds custom InfraSignal entries.
"""

import polib

PO_FILE = '/opt/infrasignal-v2/locale/ru_RU.UTF-8/LC_MESSAGES/FixMyStreet.po'

# ============================================================
# TRANSLATION DICTIONARY
# Maps English msgid → Russian msgstr
# ============================================================
TRANSLATIONS = {
    # --- Navigation / UI ---
    'Report a problem': 'Сообщить',
    'Report': 'Сообщить',
    'Your account': 'Ваш аккаунт',
    'Shortlist': 'Избранное',
    'All reports': 'Все отчёты',
    'Local alerts': 'Оповещения',
    'Help': 'Помощь',
    'Privacy': 'Конфиденц.',
    'Admin': 'Админ',
    'Sign in': 'Войти',
    'Sign out': 'Выйти',
    'Main Navigation': 'Главная навигация',
    'Continue draft report...': 'Продолжить черновик...',
    'Dashboard': 'Панель управления',

    # --- Report form ---
    'Subject': 'Тема',
    'Detail': 'Подробности',
    'Details': 'Подробности',
    'Photo': 'Фото',
    'Category': 'Категория',
    'Name': 'Имя',
    'Email': 'Эл. почта',
    'Phone': 'Телефон',
    'Password': 'Пароль',
    'Submit': 'Отправить',
    'Update': 'Обновить',
    'Cancel': 'Отмена',
    'Save': 'Сохранить',
    'Delete': 'Удалить',
    'Edit': 'Редактировать',
    'Back': 'Назад',
    'Next': 'Далее',
    'Search': 'Поиск',
    'Go': 'Перейти',
    'Close': 'Закрыть',
    'Yes': 'Да',
    'No': 'Нет',
    'None': 'Нет',
    'Other': 'Другое',
    'or': 'или',
    'and': 'и',
    'by': ' ',
    'on': 'на',
    'at': 'в',
    'to': 'к',
    'of': 'из',
    'the': '',
    'a': '',
    'an': '',

    # --- Common messages ---
    'Loading...': 'Загрузка...',
    'Please wait': 'Пожалуйста, подождите',
    'Error': 'Ошибка',
    'Success': 'Успех',
    'Warning': 'Предупреждение',
    'Thank you': 'Спасибо',
    'Thanks': 'Спасибо',
    'Sorry': 'Извините',
    'Welcome': 'Добро пожаловать',
    'Optional': 'Необязательно',
    'Required': 'Обязательно',

    # --- Report states ---
    'Open': 'Открыто',
    'Closed': 'Закрыто',
    'Fixed': 'Исправлено',
    'In progress': 'В работе',
    'Planned': 'Запланировано',
    'Action scheduled': 'Действие запланировано',
    'Investigating': 'Расследуется',
    'Unable to fix': 'Невозможно исправить',
    'Not responsible': 'Не в нашей ответственности',
    'Duplicate': 'Дубликат',
    'Internal referral': 'Внутренняя переадресация',
    'No further action': 'Дальнейшие действия не требуются',
    'Fixed - Council': 'Исправлено - Администрация',
    'Fixed - User': 'Исправлено - Пользователь',
    'Confirmed': 'Подтверждено',
    'Unconfirmed': 'Не подтверждено',
    'Hidden': 'Скрыто',
    'Partial': 'Частично',
    'All states': 'Все статусы',

    # --- Report form fields ---
    'Photo of the problem': 'Фото проблемы',
    'Please select a category': 'Пожалуйста, выберите категорию',
    'Please enter your email address': 'Пожалуйста, введите адрес эл. почты',
    'Please enter your name': 'Пожалуйста, введите ваше имя',
    'Please enter a subject': 'Пожалуйста, введите тему',
    'Please enter some details': 'Пожалуйста, введите подробности',
    'Enter a location': 'Введите местоположение',
    'Enter a nearby street name and area:': 'Введите название ближайшей улицы и район:',
    "e.g. '1600 Pennsylvania Ave, Washington DC' or 'Times Square, New York'":
        "например, '1600 Pennsylvania Ave, Washington DC' или 'Times Square, New York'",
    'locate the problem on a map of the area': 'найдите проблему на карте района',
    'enter a few details of the problem': 'введите подробности о проблеме',
    'We send it to the local authority on your behalf': 'Мы отправим это в местную администрацию от вашего имени',

    # --- Buttons and actions ---
    'Report a problem here': 'Сообщить о проблеме здесь',
    'Submit report': 'Отправить отчёт',
    'Report your problem': 'Сообщите о своей проблеме',
    'Leave an update': 'Оставить обновление',
    'Provide an update': 'Предоставить обновление',
    'Subscribe': 'Подписаться',
    'Unsubscribe': 'Отписаться',
    'Confirm': 'Подтвердить',
    'Confirm report': 'Подтвердить отчёт',
    'Confirm subscription': 'Подтвердить подписку',
    'Confirm update': 'Подтвердить обновление',
    'Skip this step': 'Пропустить этот шаг',
    'Submit update': 'Отправить обновление',
    'Hide': 'Скрыть',
    'Show': 'Показать',
    'See all reports': 'Все отчёты',

    # --- Front page ---
    'Report, view, or discuss local problems': 'Сообщайте, просматривайте и обсуждайте местные проблемы',
    '(like graffiti, fly tipping, broken paving slabs, or street lighting)':
        '(такие как граффити, незаконные свалки, сломанная тротуарная плитка или уличное освещение)',
    'How to report a problem': 'Как сообщить о проблеме',
    'Recently reported problems': 'Недавно сообщённые проблемы',
    'reports recently': 'недавних отчётов',
    'fixed in past month': 'исправлено за месяц',
    'updates on reports': 'обновлений отчётов',

    # --- Report page ---
    'Report by': 'Автор отчёта:',
    'Reported by': 'Сообщил(а)',
    'Reported at': 'Дата сообщения',
    'State:': 'Состояние:',
    'State': 'Состояние',
    'Category:': 'Категория:',
    'Sent to': 'Отправлено в',
    'Last updated': 'Последнее обновление',
    'Updates': 'Обновления',
    'This report is now closed to updates.': 'Этот отчёт больше не принимает обновления.',
    'This report is currently marked as open.': 'Этот отчёт в настоящее время отмечен как открытый.',

    # --- Account ---
    'Your reports': 'Ваши отчёты',
    'Your updates': 'Ваши обновления',
    'Your alerts': 'Ваши оповещения',
    'Change password': 'Сменить пароль',
    'Change email': 'Сменить эл. почту',
    'New password': 'Новый пароль',
    'Confirm password': 'Подтвердите пароль',
    'Current password': 'Текущий пароль',
    'Forgotten your password?': 'Забыли пароль?',

    # --- Map ---
    'Zoom in': 'Приблизить',
    'Zoom out': 'Отдалить',
    'Aerial imagery': 'Аэрофотосъёмка',
    'Map': 'Карта',
    'Satellite': 'Спутник',

    # --- Alerts page ---
    'Local alerts': 'Местные оповещения',
    'Email alerts': 'Оповещения по эл. почте',
    'New problems': 'Новые проблемы',
    'New updates': 'Новые обновления',
    'Area alerts': 'Оповещения по району',

    # --- Help/FAQ ---
    'Frequently Asked Questions': 'Часто задаваемые вопросы',
    'FAQ': 'ЧаВо',

    # --- Contact ---
    'Contact': 'Контакт',
    'Message': 'Сообщение',

    # --- Admin ---
    'Summary': 'Сводка',
    'Bodies': 'Организации',
    'Users': 'Пользователи',
    'Reports': 'Отчёты',
    'Templates': 'Шаблоны',
    'Categories': 'Категории',
    'Priorities': 'Приоритеты',
    'Defect types': 'Типы дефектов',
    'Response templates': 'Шаблоны ответов',
    'Site message': 'Сообщение на сайте',
    'Stats': 'Статистика',
    'Roles': 'Роли',
    'Permissions': 'Разрешения',

    # --- Time ---
    'today': 'сегодня',
    'yesterday': 'вчера',
    'Monday': 'Понедельник',
    'Tuesday': 'Вторник',
    'Wednesday': 'Среда',
    'Thursday': 'Четверг',
    'Friday': 'Пятница',
    'Saturday': 'Суббота',
    'Sunday': 'Воскресенье',

    # --- Statuses for display ---
    'open': 'открыто',
    'closed': 'закрыто',
    'fixed': 'исправлено',

    # --- Dashboard ---
    'All time': 'За всё время',
    'Last 7 days': 'Последние 7 дней',
    'problems reported': 'сообщённых проблем',
    'problems fixed': 'исправленных проблем',
    'Show reports in your area': 'Показать отчёты в вашем районе',
    'Select your local authority': 'Выберите вашу местную администрацию',

    # ============================================================
    # LONGER ENTRIES (with HTML, placeholders, multi-line)
    # ============================================================

    # "Don't" entries (with smart quote or ASCII apostrophe)
    '<strong>Don\u2019t forget the space</strong> in your postcode.':
        '<strong>Не забудьте пробел</strong> в вашем почтовом индексе.',
    "<strong>Don't forget the space</strong> in your postcode.":
        '<strong>Не забудьте пробел</strong> в вашем почтовом индексе.',
    '<strong>Don\u2019t mix postcodes and street names.</strong>':
        '<strong>Не смешивайте почтовые индексы и названия улиц.</strong>',
    "<strong>Don't mix postcodes and street names.</strong>":
        '<strong>Не смешивайте почтовые индексы и названия улиц.</strong>',

    # HTML entries
    '&larr; Back': '&larr; Назад',
    '<span>%s</span> saved.': '<span>%s</span> сохранено.',
    '<h2>Reports, Statistics and Actions for</h2> <h1>%s</h1>':
        '<h2>Отчёты, статистика и действия для</h2> <h1>%s</h1>',

    # Placeholder entries
    '%d characters maximum': '%d символов максимум',
    '%s bodies': '%s организаций',
    '%s currently does not accept reports from FixMyStreet.':
        '%s в настоящее время не принимает сообщения через InfraSignal.',
    'All reports within %s': 'Все отчёты в %s',
    'All reports within %s parish': 'Все отчёты в приходе %s',
    'All reports within %s ward': 'Все отчёты в районе %s',
    'All reports within %s ward, %s': 'Все отчёты в районе %s, %s',

    # Dropdowns
    ' -- Select a cobrand -- ': ' -- Выберите вариант -- ',
    '-- Pick an option --': '-- Выберите вариант --',
    '-- Please select --': '-- Пожалуйста, выберите --',
    '--Choose a template--': '--Выберите шаблон--',

    # Admin/form labels
    '(Optional - above text included by default)': '(Необязательно — текст выше включён по умолчанию)',
    '(a-z and space only)': '(только a-z и пробел)',
    '(covers roughly 200,000 people)': '(охватывает примерно 200 000 человек)',
    '(for this report)': '(для этого отчёта)',
    '(for this update)': '(для этого обновления)',
    '(no longer exists)': '(больше не существует)',
    '(sent to all)': '(отправлено всем)',

    # Fuzzy fixes
    'Add row': 'Добавить строку',
    'Add staff user': 'Добавить сотрудника',
    'Add/edit site message': 'Добавить/редактировать сообщение на сайте',

    "Can't use the map to start a report? <a href=\"%s\" rel=\"nofollow\">Skip this step</a>":
        'Не удаётся использовать карту? <a href="%s" rel="nofollow">Пропустить этот шаг</a>',

    # More standard entries
    'Abuse reports': 'Жалобы',
    'Accept photos?': 'Принимать фотографии?',
    'Active': 'Активные',
    'Add': 'Добавить',
    'Additional information for inspectors': 'Дополнительная информация для инспекторов',
    'Alert': 'Оповещение',
    'Alert options': 'Настройки оповещений',
    'Anonymize': 'Анонимизировать',
    'Anonymize report': 'Анонимизировать отчёт',
    'Are you sure?': 'Вы уверены?',
    'Area covered': 'Охватываемая территория',
    'Assigned to:': 'Назначено:',
    'Body': 'Организация',
    'Body name': 'Название организации',
    'Body not found': 'Организация не найдена',
    'Change category': 'Изменить категорию',
    'Change state': 'Изменить статус',
    'Click to select this location': 'Нажмите, чтобы выбрать это место',
    'Configuration': 'Конфигурация',
    'Contact form': 'Форма обратной связи',
    'Created': 'Создано',
    'Created problems': 'Созданные проблемы',
    'Current': 'Текущий',
    'Date': 'Дата',
    'Description': 'Описание',
    'Details of problem': 'Подробности проблемы',
    'Disabled': 'Отключено',
    'Drag the pin to the correct location': 'Перетащите метку в нужное место',
    'Edit body': 'Редактировать организацию',
    'Edit category': 'Редактировать категорию',
    'Edit report': 'Редактировать отчёт',
    'Edit user': 'Редактировать пользователя',
    'Email address': 'Адрес электронной почты',
    'Enabled': 'Включено',
    'Enter a postcode or street name': 'Введите почтовый индекс или название улицы',
    'External ID': 'Внешний ID',
    'Filter': 'Фильтр',
    'Fixed problems': 'Исправленные проблемы',
    'Flag': 'Отметить',
    'Flagged': 'Отмечено',
    'From': 'От',
    'From body': 'От организации',
    'Go back': 'Вернуться',
    'High': 'Высокий',
    'ID': 'ID',
    'Inactive': 'Неактивные',
    'Inspector report': 'Отчёт инспектора',
    'Invalid email': 'Неверный адрес эл. почты',
    'Last 4 weeks': 'Последние 4 недели',
    'Last updated:': 'Последнее обновление:',
    'Latitude': 'Широта',
    'Location': 'Местоположение',
    'Log entry': 'Запись в журнале',
    'Longitude': 'Долгота',
    'Low': 'Низкий',
    'Make private': 'Сделать приватным',
    'Mark as duplicate': 'Отметить как дубликат',
    'Medium': 'Средний',
    'Moderate': 'Модерировать',
    'Moderate report': 'Модерировать отчёт',
    'New': 'Новый',
    'No reports': 'Нет отчётов',
    'Normal': 'Нормальный',
    'Note': 'Примечание',
    'Notes': 'Примечания',
    'Not set': 'Не установлено',
    'Number of reports': 'Количество отчётов',
    'Order': 'Порядок',
    'Page %d of %d': 'Страница %d из %d',
    'Pending': 'Ожидает',
    'Phone number': 'Номер телефона',
    'Pin is not in the right place?': 'Метка не в нужном месте?',
    'Previous page': 'Предыдущая страница',
    'Next page': 'Следующая страница',
    'Private': 'Приватный',
    'Problem has been fixed.': 'Проблема исправлена.',
    'Problem has not been fixed.': 'Проблема не исправлена.',
    'Priority': 'Приоритет',
    'Reopen': 'Переоткрыть',
    'Reply': 'Ответить',
    'Response': 'Ответ',
    'Role': 'Роль',
    'Save changes': 'Сохранить изменения',
    'Scheduled': 'Запланировано',
    'Select': 'Выбрать',
    'Select all': 'Выбрать всё',
    'Send': 'Отправить',
    'Send method': 'Метод отправки',
    'Sent': 'Отправлено',
    'Status': 'Статус',
    'Street name': 'Название улицы',
    'Subcategory': 'Подкатегория',
    'Take photo': 'Сделать фото',
    'Text': 'Текст',
    'Title': 'Заголовок',
    'To': 'Кому',
    'Total': 'Всего',
    'Type': 'Тип',
    'Upload photo': 'Загрузить фото',
    'User': 'Пользователь',
    'Username': 'Имя пользователя',
    'View report': 'Просмотреть отчёт',

    # --- Filter labels ---
    'Sort by': 'Сортировать по',
    'Newest first': 'Сначала новые',
    'Oldest first': 'Сначала старые',
    'Most commented': 'Самые обсуждаемые',

    # --- Privacy / About links ---
    'Terms': 'Условия',
    'About': 'О нас',

    # --- Questionnaire ---
    'Has the problem been fixed?': 'Проблема была исправлена?',
    'An update has been left on this problem.': 'К этой проблеме добавлено обновление.',

    # --- Email subjects and text ---
    'Problem Report': 'Отчёт о проблеме',
    'Your report has been sent.': 'Ваш отчёт отправлен.',
    'Your update has been posted.': 'Ваше обновление опубликовано.',

    # --- Errors ---
    'Page not found': 'Страница не найдена',
    'Internal server error': 'Внутренняя ошибка сервера',
    'Unauthorized': 'Не авторизован',
    'Forbidden': 'Запрещено',
    'Sorry, we couldn\u2019t find that page.': 'Извините, мы не смогли найти эту страницу.',
    "Sorry, we couldn't find that page.": 'Извините, мы не смогли найти эту страницу.',
    
    # ============================================================
    # CUSTOM INFRASIGNAL ENTRIES (from Spanish, need Russian translations)
    # ============================================================
    'Pick your local authority': 'Выберите вашу местную администрацию',
    'Top 5 responsive local authorities': 'Топ-5 самых отзывчивых местных администраций',
    'About InfraSignal': 'Об InfraSignal',
    'Privacy Policy': 'Политика конфиденциальности',
    'Terms of Use': 'Условия использования',

    # SightEngine content moderation
    'Submission Error — Please fix the following:': 'Ошибка отправки — Пожалуйста, исправьте следующее:',
    'Your subject contains content that is not allowed: ': 'Ваша тема содержит недопустимый контент: ',
    'Your details contain content that is not allowed: ': 'Ваши данные содержат недопустимый контент: ',
    'Your update contains content that is not allowed: ': 'Ваше обновление содержит недопустимый контент: ',
    'Inappropriate content detected: %s (%d%% confidence)': 'Обнаружен неуместный контент: %s (%d%% уверенности)',
    'Weapon detected: %s (%d%% confidence)': 'Обнаружено оружие: %s (%d%% уверенности)',
    'Violence detected (%d%% confidence)': 'Обнаружено насилие (%d%% уверенности)',
    'Offensive/hate content detected (%d%% confidence)': 'Обнаружен оскорбительный контент (%d%% уверенности)',
    'Graphic/gory content detected (%d%% confidence)': 'Обнаружен графический/жёсткий контент (%d%% уверенности)',
    'Self-harm content detected (%d%% confidence)': 'Обнаружен контент с самоповреждением (%d%% уверенности)',
    'Alcohol content detected (%d%% confidence)': 'Обнаружен контент с алкоголем (%d%% уверенности)',
    'Drug-related content detected (%d%% confidence)': 'Обнаружен контент с наркотиками (%d%% уверенности)',
    'Tobacco/smoking content detected (%d%% confidence)': 'Обнаружен контент с табаком/курением (%d%% уверенности)',
    'Gambling content detected (%d%% confidence)': 'Обнаружен контент с азартными играми (%d%% уверенности)',
    'Money/banknote display detected (%d%% confidence)': 'Обнаружены деньги/банкноты (%d%% уверенности)',
    'Image appears to be AI-generated (%d%% confidence)': 'Изображение создано ИИ (%d%% уверенности)',
    'Image quality too low (%d%% quality score, minimum %d%% required)': 'Качество изображения слишком низкое (%d%% качества, требуется минимум %d%%)',
    'Duplicate or near-duplicate image detected (%d%% similarity match)': 'Обнаружено дублирующее изображение (%d%% совпадения)',

    # SightEngine text moderation
    'profanity found: ': 'найдена ненормативная лексика: ',
    'personal information found: ': 'найдена личная информация: ',
    'URL/link found in image': 'Обнаружена ссылка в изображении',
    'social media account reference found': 'найдена ссылка на аккаунт соц. сети',
    'extremist content found in text': 'обнаружен экстремистский контент',
    'drug reference found in text': 'обнаружена ссылка на наркотики',
    'weapon reference found in text': 'обнаружена ссылка на оружие',
    'violent language found in text': 'обнаружен агрессивный контент',
    'self-harm references found in text': 'обнаружены ссылки на самоповреждение',
    'spam content found in text': 'обнаружен спам-контент',
    'content trading solicitation found': 'обнаружен контент торговли',
    'money transaction solicitation found': 'обнаружен контент о денежных переводах',
    'Text in image flagged: ': 'Текст в изображении отмечен: ',
    'Text flagged as %s (%d%% confidence)': 'Текст отмечен как %s (%d%% уверенности)',
    'Profanity detected in text: ': 'Ненормативная лексика в тексте: ',
    'Personal information in text: ': 'Личная информация в тексте: ',
    'URL/link found in text': 'Обнаружена ссылка в тексте',

    # Alert page
    'To find out what local alerts we have for you, please enter your street name and area':
        'Чтобы узнать, какие местные оповещения доступны, введите название улицы и район',

    # Contact page
    "Please do <strong>not</strong> report problems through this form; messages go to\nthe team behind this site, not a local authority. To report a problem,\nplease <a href=\"/\">go to the front page</a> and follow the instructions.":
        "Пожалуйста, <strong>не</strong> сообщайте о проблемах через эту форму; сообщения направляются\nкоманде сайта, а не в местную администрацию. Чтобы сообщить о проблеме,\nпожалуйста, <a href=\"/\">перейдите на главную страницу</a> и следуйте инструкциям.",

    # RSS/Alerts
    '%s has a variety of RSS feeds and email alerts for local problems, including\nalerts for all problems within a particular ward or local authority, or all problems\nwithin a certain distance of a particular location.':
        '%s предоставляет различные RSS-каналы и оповещения по эл. почте о местных проблемах, включая\nоповещения обо всех проблемах в определённом районе или муниципалитете, или обо всех проблемах\nв определённом радиусе от конкретного места.',

    # Stats
    '%s opened, %s closed, %s fixed': '%s открыто, %s закрыто, %s исправлено',
    'How responsive is %s?': 'Насколько отзывчив(а) %s?',
    'Within the specified timeframe:': 'В указанный период:',

    # --- Additional common entries from the .po file ---
    'show more': 'показать ещё',
    'show less': 'показать меньше',
    'Expand map': 'Развернуть карту',
    'Shrink map': 'Уменьшить карту',
    'Check your email': 'Проверьте вашу почту',
    'Please check your email': 'Пожалуйста, проверьте вашу почту',
    'Confirm your email address': 'Подтвердите ваш адрес эл. почты',
    'Please click on the link in the email': 'Пожалуйста, нажмите на ссылку в письме',
    'Resend confirmation email': 'Отправить подтверждение повторно',
    'Create account': 'Создать аккаунт',
    'with a password': 'с паролем',
    'with a link': 'по ссылке',
    'Sign in with a password': 'Войти с паролем',
    'or sign in by email': 'или войти по эл. почте',
    'No account? Sign up': 'Нет аккаунта? Зарегистрируйтесь',
    'Please solve the CAPTCHA': 'Пожалуйста, пройдите проверку CAPTCHA',
    'Please provide your email address': 'Пожалуйста, укажите адрес эл. почты',
    'Please provide your name.': 'Пожалуйста, укажите ваше имя.',
    'Tick here to receive email updates': 'Отметьте здесь для получения обновлений по эл. почте',
    'RSS feed': 'RSS-канал',
    'Previous': 'Предыдущий',
    'Older': 'Старше',
    'Newer': 'Новее',
    'of': 'из',
    'Click the link below to confirm your report on %s:': 'Нажмите на ссылку ниже, чтобы подтвердить ваш отчёт на %s:',
    'Your latest update will then be shown on the site.': 'Ваше последнее обновление будет показано на сайте.',
    'Your report will then be shown on the site.': 'Ваш отчёт будет показан на сайте.',
    'Confirm your update on %s': 'Подтвердите ваше обновление на %s',
    'Confirm your report on %s': 'Подтвердите ваш отчёт на %s',
    'Your email has been confirmed.': 'Ваш адрес эл. почты подтверждён.',
    'Thank you for reporting this problem.': 'Спасибо за сообщение об этой проблеме.',
    'Your report has been sent to the council.': 'Ваш отчёт отправлен в администрацию.',
    'Your password has been changed': 'Ваш пароль изменён',
    'New report by %s at %s': 'Новый отчёт от %s в %s',
    'Problem Report: %s': 'Отчёт о проблеме: %s',
    '%s: new report – %s': '%s: новый отчёт — %s',
    '%s: update – %s': '%s: обновление — %s',
    'A problem has been reported at the following location:': 'О проблеме сообщено в следующем месте:',
    'More information: %s': 'Подробнее: %s',
    'View report on site': 'Посмотреть отчёт на сайте',

    # Admin pages
    'Search Reports': 'Поиск отчётов',
    'Search Users': 'Поиск пользователей',
    'Add body': 'Добавить организацию',
    'Send method:': 'Метод отправки:',
    'Add category': 'Добавить категорию',
    'Edit role': 'Редактировать роль',
    'Add role': 'Добавить роль',
    'Create body': 'Создать организацию',
    'Create user': 'Создать пользователя',
    'No users found': 'Пользователи не найдены',
    'No bodies found': 'Организации не найдены',
    'No categories found': 'Категории не найдены',
    'Superuser': 'Суперпользователь',
    'Staff': 'Сотрудник',
    'Inspect report': 'Проверить отчёт',
    'Edit permissions': 'Редактировать разрешения',
    'Save permissions': 'Сохранить разрешения',

    # Footer and misc
    'Built by': 'Создано',
    'Powered by': 'Работает на',
    'Version': 'Версия',
}

def main():
    po = polib.pofile(PO_FILE)
    translated_count = 0
    fuzzy_fixed = 0
    custom_added = 0
    skipped = []

    # --- 1. Fix fuzzy entries ---
    for entry in po.fuzzy_entries():
        if entry.msgid in TRANSLATIONS:
            entry.msgstr = TRANSLATIONS[entry.msgid]
            if 'fuzzy' in entry.flags:
                entry.flags.remove('fuzzy')
            fuzzy_fixed += 1

    # --- 2. Translate untranslated entries ---
    for entry in po.untranslated_entries():
        if entry.msgid in TRANSLATIONS:
            if entry.msgid_plural:
                # Plural entry — Russian has 3 forms (nplurals=3)
                base = TRANSLATIONS[entry.msgid]
                entry.msgstr_plural = {0: base, 1: base, 2: base}
            else:
                entry.msgstr = TRANSLATIONS[entry.msgid]
            translated_count += 1
        else:
            skipped.append(entry.msgid[:80])

    # --- 3. Add custom InfraSignal entries ---
    existing_ids = set(e.msgid for e in po)
    custom_entries = {
        'Pick your local authority',
        'Top 5 responsive local authorities',
        'About InfraSignal',
        'Privacy Policy',
        'Terms of Use',
        'Submission Error — Please fix the following:',
        'Your subject contains content that is not allowed: ',
        'Your details contain content that is not allowed: ',
        'Your update contains content that is not allowed: ',
        'Inappropriate content detected: %s (%d%% confidence)',
        'Weapon detected: %s (%d%% confidence)',
        'Violence detected (%d%% confidence)',
        'Offensive/hate content detected (%d%% confidence)',
        'Graphic/gory content detected (%d%% confidence)',
        'Self-harm content detected (%d%% confidence)',
        'Alcohol content detected (%d%% confidence)',
        'Drug-related content detected (%d%% confidence)',
        'Tobacco/smoking content detected (%d%% confidence)',
        'Gambling content detected (%d%% confidence)',
        'Money/banknote display detected (%d%% confidence)',
        'Image appears to be AI-generated (%d%% confidence)',
        'Image quality too low (%d%% quality score, minimum %d%% required)',
        'Duplicate or near-duplicate image detected (%d%% similarity match)',
        'profanity found: ',
        'personal information found: ',
        'URL/link found in image',
        'social media account reference found',
        'extremist content found in text',
        'drug reference found in text',
        'weapon reference found in text',
        'violent language found in text',
        'self-harm references found in text',
        'spam content found in text',
        'content trading solicitation found',
        'money transaction solicitation found',
        'Text in image flagged: ',
        'Text flagged as %s (%d%% confidence)',
        'Profanity detected in text: ',
        'Personal information in text: ',
        'URL/link found in text',
        'To find out what local alerts we have for you, please enter your street name and area',
        "Please do <strong>not</strong> report problems through this form; messages go to\nthe team behind this site, not a local authority. To report a problem,\nplease <a href=\"/\">go to the front page</a> and follow the instructions.",
        '%s has a variety of RSS feeds and email alerts for local problems, including\nalerts for all problems within a particular ward or local authority, or all problems\nwithin a certain distance of a particular location.',
        '%s opened, %s closed, %s fixed',
        'How responsive is %s?',
        'Within the specified timeframe:',
    }

    for msgid in custom_entries:
        if msgid not in existing_ids and msgid in TRANSLATIONS:
            entry = polib.POEntry(msgid=msgid, msgstr=TRANSLATIONS[msgid])
            po.append(entry)
            custom_added += 1

    po.save()

    print(f"=== TRANSLATION COMPLETE ===")
    print(f"Translated: {translated_count}")
    print(f"Fuzzy fixed: {fuzzy_fixed}")
    print(f"Custom entries added: {custom_added}")
    print(f"Skipped (no translation): {len(skipped)}")

    # Re-check stats
    po2 = polib.pofile(PO_FILE)
    print(f"\n=== FINAL STATS ===")
    print(f"Total entries: {len(po2)}")
    print(f"Translated: {len(po2.translated_entries())}")
    print(f"Fuzzy: {len(po2.fuzzy_entries())}")
    print(f"Untranslated: {len(po2.untranslated_entries())}")

    if skipped:
        print(f"\n=== REMAINING UNTRANSLATED (first 30) ===")
        for i, s in enumerate(skipped[:30]):
            print(f"  {i+1}. {s!r}")

if __name__ == '__main__':
    main()
