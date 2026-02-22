#!/usr/bin/env python3
"""
Russian translation pass 3 - Final: translate remaining 130 untranslated + fix 68 fuzzy.
"""
import polib

PO_FILE = '/opt/infrasignal-v2/locale/ru_RU.UTF-8/LC_MESSAGES/FixMyStreet.po'

T = {
    # Remaining 130 untranslated
    '<a href="%s">SocietyWorks</a> is a limited company (05798215). It is a trading subsidiary of <a href="%s">mySociety</a>, a registered charity in England and Wales (1076346).':
        '<a href="%s">SocietyWorks</a> — компания с ограниченной ответственностью (05798215). Она является дочерней компанией <a href="%s">mySociety</a>, зарегистрированной благотворительной организации в Англии и Уэльсе (1076346).',
    "Category changed from \u2018%s\u2019 to \u2018%s\u2019":
        'Категория изменена с «%s» на «%s»',
    'Check <a href="/about/house-rules" target="_blank">what\'s acceptable</a>':
        'Проверьте <a href="/about/house-rules" target="_blank">что допустимо</a>',
    "Check you <strong>haven\u2019t swapped numbers and letters</strong>. <code>O</code>, <code>0</code>, <code>I</code> and <code>1</code> aren\u2019t the same.":
        'Убедитесь, что вы <strong>не перепутали буквы и цифры</strong>. <code>O</code>, <code>0</code>, <code>I</code> и <code>1</code> — это не одно и то же.',
    'Does this report break our <a href="/about/house-rules">Conditions of Use</a>? Use this form to let us know.':
        'Этот отчёт нарушает наши <a href="/about/house-rules">Условия использования</a>? Сообщите нам через эту форму.',
    "Don\u2019t identify or accuse other&nbsp;people":
        'Не называйте и не обвиняйте&nbsp;других',
    "Don\u2019t include private contact details in the&nbsp;description":
        'Не включайте личные контактные данные в&nbsp;описание',
    "Enable <strong>Always fetch all problems</strong> if you've enabled Open311 problem-fetching above\n                and the endpoint always returns a list of all problems. This will suppress error messages about\n                bad dates in the problems fetched.":
        'Включите <strong>Всегда получать все проблемы</strong>, если вы включили получение проблем через Open311 выше\n                и сервер всегда возвращает список всех проблем. Это подавит сообщения об ошибках\n                неверных дат в полученных проблемах.',
    "Enable <strong>Convert location from Easting/Northing</strong> if you've enabled Open311 problem-fetching above\n                and problems fetching from the endpoint have the location in Easting/Northings and not Latitude/Longitude.":
        'Включите <strong>Преобразование координат из Easting/Northing</strong>, если вы включили получение проблем через Open311 выше\n                и проблемы с сервера содержат координаты в формате Easting/Northing, а не Широта/Долгота.',
    "Enable <strong>Open311 problem-fetching</strong> if you want to display reports created at\n          the endpoint to FixMyStreet. If you're not sure, you probably do not, so leave this unchecked.\n          For more information, see \n          <a href='https://www.mysociety.org/2013/02/20/open311-extended/' class='admin-offsite-link'>this article</a>.":
        'Включите <strong>Получение проблем через Open311</strong>, если вы хотите отображать отчёты, созданные\n          на стороннем сервере. Если вы не уверены, оставьте это выключенным.\n          Подробнее см.\n          <a href=\'https://www.mysociety.org/2013/02/20/open311-extended/\' class=\'admin-offsite-link\'>эту статью</a>.',
    'Enabling this will suppress the error message that is normally emitted when an update has no description':
        'Включение этого подавит сообщение об ошибке, которое обычно появляется, когда обновление не содержит описания',
    "Enter a Z\u00fcrich street name":
        'Введите название улицы в Цюрихе',
    "Even a small donation of \u00a35 today will help mySociety run sites like FixMyStreet.":
        'Даже небольшое пожертвование сегодня поможет поддержать работу таких сайтов, как InfraSignal.',
    "Fill in the form below to start your report and click \u2018save draft\u2019 when you\u2019re done. For peace of mind, any information you provide here will also be saved automatically. When you\u2019re connected to the internet again, come back to finish and submit it.":
        'Заполните форму ниже для создания отчёта и нажмите «сохранить черновик» по завершении. Вся информация будет также сохранена автоматически. Когда вы снова подключитесь к интернету, вернитесь, чтобы завершить и отправить его.',
    "Find the answers to some of our most frequently asked questions about how FixMyStreet works for councils and discover your options for integrating with the service.":
        'Найдите ответы на часто задаваемые вопросы о работе InfraSignal для администраций и узнайте о возможностях интеграции с сервисом.',
    "FixMyStreet helps you send a report to your council, but we\u2019re not responsible for fixing things. If you\u2019d like to chase your issue, please search your inbox for the latest reply, or auto-reply from your council, and respond to that.":
        'InfraSignal помогает отправить отчёт в вашу администрацию, но мы не отвечаем за устранение проблем. Если хотите проследить за решением, найдите последний ответ от администрации в своей почте и ответьте на него.',
    'FixMyStreet is a service provided by mySociety, which is a registered charity, charity number 1076346.':
        'InfraSignal — сервис, предоставляемый mySociety, зарегистрированной благотворительной организацией, номер 1076346.',
    "FixMyStreet\u2019s code is open source. If you\u2019d like to contribute to it, or create a version of the site in your country, find everything you need at fixmystreet.org.":
        'Код InfraSignal является открытым. Если вы хотите внести вклад или создать версию сайта для своей страны, всё необходимое вы найдёте на fixmystreet.org.',
    'Free FixMyStreet goodies for you!':
        'Бесплатные материалы InfraSignal для вас!',
    "From a UK Local Council and interested in finding out about FixMyStreet Pro?":
        'Вы из местной администрации и хотите узнать больше об InfraSignal Pro?',
    "Give this collection of fields a name. It is not shown publicly, just here in the admin.":
        'Дайте этой группе полей название. Оно не отображается публично, только в админке.',
    'Help <strong>%s</strong> resolve your problem quicker, by providing some extra detail. This extra information will not be published online.':
        'Помогите <strong>%s</strong> решить вашу проблему быстрее, предоставив дополнительные сведения. Эта информация не будет опубликована.',
    "Here is a list of draft reports you made offline. Click Continue to finish making a report online, or Delete to remove a draft report.":
        'Вот список черновиков отчётов, созданных офлайн. Нажмите «Продолжить» для завершения онлайн или «Удалить» для удаления черновика.',
    "If there's a user associated with the address you entered, we've sent a confirmation email.":
        'Если с указанным адресом связан пользователь, мы отправили письмо с подтверждением.',
    "If there\u2019s a better contact address for the reports you are receiving, tell us by emailing support@fixmystreet.com and we\u2019ll update it for you.":
        'Если есть лучший контактный адрес для получаемых отчётов, сообщите нам по эл. почте, и мы обновим его.',
    "If this priority is passed to an external service (e.g. Exor/Confirm) enter the priority code to use with that service here.":
        'Если этот приоритет передаётся во внешнюю систему (напр. Exor/Confirm), введите код приоритета для этой системы.',
    "If ticked, the form will be disabled and this item\u2019s notice text will be displayed.":
        'Если отмечено, форма будет отключена, и будет показан текст уведомления.',
    "If ticked, this extra data will not be edited or deleted by the Open311 population script.":
        'Если отмечено, эти данные не будут изменены или удалены скриптом Open311.',
    "If ticked, this template will be used for Open311 updates that put problems in this state.":
        'Если отмечено, этот шаблон будет использоваться для обновлений Open311, переводящих проблемы в этот статус.',
    "If you are contacting us about a specific report or update please include a link to the report in the message.":
        'Если вы обращаетесь по конкретному отчёту, пожалуйста, включите ссылку на него в сообщение.',
    "If you generate a new token the existing token will no longer work.":
        'При создании нового токена существующий перестанет работать.',
    'If you have questions about FixMyStreet':
        'Если у вас есть вопросы об InfraSignal',
    "If you let us know your email address, we\u2019ll notify you when this problem is updated or fixed.":
        'Если вы укажете свой адрес эл. почты, мы уведомим вас, когда проблема будет обновлена или решена.',
    'If you made the original report please <a href="%s">log in</a> to leave an update.':
        'Если вы автор отчёта, <a href="%s">войдите</a>, чтобы оставить обновление.',
    "If you only want this priority to be an option for specific categories, pick them here. By default they will show for all categories.":
        'Если вы хотите, чтобы этот приоритет был доступен только для определённых категорий, выберите их здесь. По умолчанию он отображается для всех.',
    "If you only want this template to be an option for specific categories, pick them here. By default they will show for all categories.":
        'Если вы хотите, чтобы этот шаблон был доступен только для определённых категорий, выберите их здесь. По умолчанию он отображается для всех.',
    'If you submit a problem here the problem will <strong>not</strong> be reported to the council.':
        'Если вы отправите проблему здесь, она <strong>не</strong> будет передана в администрацию.',
    "If you want to use this template to prefill the update field when a report&rsquo;s <strong>external</strong> (e.g. Confirm) status code changes, enter the status code here.":
        'Если вы хотите использовать этот шаблон для предзаполнения поля обновления при изменении <strong>внешнего</strong> (напр. Confirm) кода статуса отчёта, введите код статуса здесь.',
    "If you want to use this template to prefill the update field when changing a report&rsquo;s state, select the state here.":
        'Если вы хотите использовать этот шаблон для предзаполнения поля обновления при изменении статуса отчёта, выберите статус здесь.',
    "If you wish to contact us by post, our address is <address>mySociety, 483 Green Lanes, London, N13 4BS, UK.</address>":
        'Если вы хотите связаться с нами по почте, наш адрес: <address>mySociety, 483 Green Lanes, London, N13 4BS, UK.</address>',
    "If you&rsquo;d like to discuss this then <a href=\"/contact\">get in touch</a>.":
        'Если хотите обсудить это, <a href="/contact">свяжитесь с нами</a>.',
    "If you've enabled Open311 update-sending above, Open311 usually only accepts OPEN or CLOSED status in \n              its updates. Enable <strong>extended Open311 stauses</strong> if you want to allow extra states to be passed.\n              Check that your cobrand supports this feature before switching it on.":
        'Если вы включили отправку обновлений Open311 выше, Open311 обычно принимает только статусы OPEN или CLOSED.\n              Включите <strong>расширенные статусы Open311</strong>, если хотите передавать дополнительные статусы.\n              Убедитесь, что ваш кобренд поддерживает эту функцию.',
    "If you've enabled Open311 update-sending above, enable <strong>suppression of alerts</strong> \n              if you do <strong>not</strong> want that user to be notified whenever these updates are created.":
        'Если вы включили отправку обновлений Open311 выше, включите <strong>подавление оповещений</strong>,\n              если вы <strong>не</strong> хотите, чтобы пользователь получал уведомления при создании этих обновлений.',
    "If you've enabled Open311 update-sending above, you must identify which \n              FixMyStreet <strong>user</strong> will be attributed as the creator of those updates\n              when they are shown on the site. Enter the ID (number) of that user.":
        'Если вы включили отправку обновлений Open311 выше, укажите, какой\n              <strong>пользователь</strong> InfraSignal будет указан как автор этих обновлений\n              при их отображении на сайте. Введите ID (номер) этого пользователя.',
    "If you\u2019re <strong>not sure on the spelling</strong>, try another nearby street you <em>are</em> sure about, then trace your way back on our map.":
        'Если вы <strong>не уверены в написании</strong>, попробуйте другую ближайшую улицу, в которой вы <em>уверены</em>, а затем найдите нужное место на карте.',
    "If you\u2019ve made changes, leave a note explaining what, for other admins to see.":
        'Если вы внесли изменения, оставьте пояснение для других администраторов.',
    "Is a litter category for the purposes of receiving reports on National Highways roads":
        'Является категорией мусора для приёма отчётов на автомагистралях',
    "It looks like you\u2019re not connected to the internet right now. Don\u2019t worry, you can start a report below, save it as a draft and finish it when you\u2019re connected to the internet again. You can create multiple draft reports if you need to report more than one problem.":
        'Похоже, вы сейчас не подключены к интернету. Не волнуйтесь, вы можете начать отчёт ниже, сохранить его как черновик и завершить при подключении к интернету. Вы можете создать несколько черновиков.',
    "Mapping and reporting street problems to the councils responsible for fixing them &ndash; anywhere in the UK.":
        'Картирование и сообщение о проблемах на улицах ответственным организациям &ndash; в любой точке.',
    "Meanwhile, if you\u2019re getting nowhere, you might consider writing to your local councillor or other representative to see if they can help.":
        'Если дело не продвигается, попробуйте обратиться к местному депутату или представителю.',
    "Need to report a problem in your local area? Learn all about FixMyStreet, how it works and what happens to your report once you&rsquo;ve made it.":
        'Нужно сообщить о проблеме в вашем районе? Узнайте всё об InfraSignal: как он работает и что происходит с вашим отчётом после отправки.',
    "Normal (public) users should not be associated with any <strong>area</strong>.<br>\n                  Authorised staff users can be associated with the area in which they operate.":
        'Обычные пользователи не должны быть привязаны к <strong>районам</strong>.<br>\n                  Авторизованные сотрудники могут быть привязаны к району, в котором они работают.',
    'Please generate a two-factor code and enter it below:':
        'Сгенерируйте двухфакторный код и введите его ниже:',
    'Please look at our <a href="/pro/">dedicated site</a>.':
        'Посмотрите наш <a href="/pro/">специализированный сайт</a>.',
    "Please scan this image with your app, or enter the text code into your app, then generate a new one-time code and enter it below:":
        'Отсканируйте это изображение приложением или введите текстовый код в приложение, затем сгенерируйте одноразовый код и введите его ниже:',
    "Prevent new reports from using this category, <em>and</em> also remove it from map filters.":
        'Запретить новые отчёты в этой категории <em>и</em> убрать её из фильтров карты.',
    "Prevent new reports from using this category, but keep it available in map filters.":
        'Запретить новые отчёты в этой категории, но оставить её в фильтрах карты.',
    'Prevent user from submitting the form until this field is filled in.':
        'Запретить отправку формы, пока это поле не заполнено.',
    'Reports are limited to {0} characters in length. Please shorten your report':
        'Длина отчёта ограничена {0} символами. Пожалуйста, сократите текст отчёта',
    "Reports near %s are sent to different councils, depending on the type of problem.":
        'Отчёты рядом с %s направляются в разные организации в зависимости от типа проблемы.',
    'Reports to %s are currently sent directly into backend services.':
        'Отчёты в %s в настоящее время отправляются напрямую в серверные системы.',
    'Roles can be associated with the categories in which they operate.':
        'Роли могут быть связаны с категориями, в которых они действуют.',
    "Say how long the issue\u2019s been&nbsp;present":
        'Укажите, как давно существует&nbsp;проблема',
    "Sign in by email instead, providing a new password. When you click the link in your email, your password will be updated.":
        'Войдите через эл. почту, указав новый пароль. При переходе по ссылке в письме ваш пароль будет обновлён.',
    "Sign in by email or text, providing a new password. When you click the link in your email or enter the SMS authentication code, your password will be updated.":
        'Войдите через эл. почту или SMS, указав новый пароль. При переходе по ссылке или вводе кода ваш пароль будет обновлён.',
    "Sorry, you don\u2019t have permission to do that. If you are the problem reporter, or a member of staff, please <a href=\"%s\">sign in</a> to view this report.":
        'У вас нет разрешения на это. Если вы автор отчёта или сотрудник, <a href="%s">войдите</a> для просмотра.',
    'Spread the word about FixMyStreet!':
        'Расскажите об InfraSignal!',
    'Summaries are limited to %d characters in length. Please shorten your summary':
        'Описание ограничено %d символами. Пожалуйста, сократите текст',
    'Summaries are limited to %s characters in length. Please shorten your summary':
        'Описание ограничено %s символами. Пожалуйста, сократите текст',
    'Summaries are limited to {0} characters in length. Please shorten your summary':
        'Описание ограничено {0} символами. Пожалуйста, сократите текст',
    "Superusers have permission to perform <strong>all actions</strong> within the admin.":
        'Суперпользователи имеют разрешение выполнять <strong>все действия</strong> в админпанели.',
    'Thanks, you have successfully enabled two-factor authentication on your account.':
        'Спасибо, вы успешно включили двухфакторную аутентификацию в своём аккаунте.',
    "That password has appeared in a known third-party data breach (<a href=\"https://haveibeenpwned.com/Passwords\" target=\"_blank\">more information</a>); please choose another":
        'Этот пароль был обнаружен в известной утечке данных (<a href="https://haveibeenpwned.com/Passwords" target="_blank">подробнее</a>); пожалуйста, выберите другой',
    "The <strong>FixMyStreet name</strong> is a string that represents the name of the web application as it is usually displayed to the user (e.g., amongst a list of other applications, or as a label for an icon).":
        '<strong>Название InfraSignal</strong> — строка, представляющая имя веб-приложения, как оно обычно отображается пользователю (напр., в списке приложений или как подпись к иконке).',
    "The <strong>FixMyStreet short name</strong> is a string that represents the name of the web application displayed to the user if there is not enough space to display name (e.g., as a label for an icon on the phone home screen).":
        '<strong>Краткое название InfraSignal</strong> — строка, представляющая имя веб-приложения при нехватке места (напр., как подпись к иконке на экране телефона).',
    "The <strong>WasteWorks name</strong> is a string that represents the name of the web application as it is usually displayed to the user (e.g., amongst a list of other applications, or as a label for an icon).":
        '<strong>Название WasteWorks</strong> — строка, представляющая имя веб-приложения, как оно обычно отображается пользователю.',
    "The <strong>WasteWorks short name</strong> is a string that represents the name of the web application displayed to the user if there is not enough space to display name (e.g., as a label for an icon on the phone home screen).":
        '<strong>Краткое название WasteWorks</strong> — строка, представляющая имя веб-приложения при нехватке места.',
    "The <strong>background colour</strong> defines a placeholder background colour for the application splash screen before it has loaded.  Colours should be specified with CSS syntax, e.g. <strong><code>#ff00ff</code></strong> or <strong><code>rgb(255, 0, 255)</code></strong> or a named colour like <strong><code>fuchsia</code></strong>.":
        '<strong>Цвет фона</strong> определяет цвет-заполнитель экрана загрузки приложения. Указывайте цвета в синтаксисе CSS, напр. <strong><code>#ff00ff</code></strong> или <strong><code>rgb(255, 0, 255)</code></strong> или именованный цвет, напр. <strong><code>fuchsia</code></strong>.',
    "The <strong>icons</strong> are used when the application is installed to the user's home screen. Icons must be <strong>square</strong>, with <strong>512x512</strong>px and <strong>192x192</strong>px being the most common sizes.":
        '<strong>Иконки</strong> используются при установке приложения на домашний экран. Иконки должны быть <strong>квадратными</strong>, наиболее распространённые размеры — <strong>512x512</strong>px и <strong>192x192</strong>px.',
    "The <strong>theme colour</strong> defines the default theme colour for the application. This sometimes affects how the OS displays the site (e.g., on Android's task switcher, the theme colour surrounds the site). Colours should be specified with CSS syntax, e.g. <strong><code>#ff00ff</code></strong> or <strong><code>rgb(255, 0, 255)</code></strong> or a named colour like <strong><code>fuchsia</code></strong>.":
        '<strong>Цвет темы</strong> определяет основной цвет темы приложения. Иногда влияет на отображение сайта в ОС (напр., в переключателе задач Android). Указывайте цвета в синтаксисе CSS, напр. <strong><code>#ff00ff</code></strong> или <strong><code>rgb(255, 0, 255)</code></strong>.',
    'The code used to store this field value in the database.':
        'Код, используемый для хранения значения этого поля в базе данных.',
    "The role\u2019s <strong>name</strong> is used to refer to this group of permissions elsewhere in the admin.":
        '<strong>Название</strong> роли используется для ссылки на эту группу разрешений в админке.',
    "There was a problem with your login information. If you cannot remember your password, or do not have one, please fill in the \u2018No\u2019 section of the form.":
        'Проблема с вашими данными для входа. Если вы не помните пароль, заполните раздел «Нет» в форме.',
    "There was a problem with your login information. If you cannot remember your password, or do not have one, please select \u2018Fill in your details manually\u2019.":
        'Проблема с вашими данными для входа. Если вы не помните пароль, выберите «Заполните данные вручную».',
    'These categories appear in more than one group:':
        'Эти категории появляются в нескольких группах:',
    "These details will be sent to the council, but will never be shown online without your permission.":
        'Эти данные будут отправлены в администрацию, но не будут показаны в интернете без вашего разрешения.',
    'These details will never be shown online without your permission.':
        'Эти данные не будут показаны в интернете без вашего разрешения.',
    "These users weren\u2019t updated.":
        'Эти пользователи не были обновлены.',
    "These users weren't updated.":
        'Эти пользователи не были обновлены.',
    "These will be published online for others to see, in accordance with our <a href=\"%s\">privacy policy</a>.":
        'Они будут опубликованы для всеобщего обозрения в соответствии с нашей <a href="%s">политикой конфиденциальности</a>.',
    "These will be sent to <strong>%s</strong> and also published online for others to see, in accordance with our <a href=\"%s\">privacy policy</a>.":
        'Они будут отправлены в <strong>%s</strong> и опубликованы для всеобщего обозрения в соответствии с нашей <a href="%s">политикой конфиденциальности</a>.',
    'These will be sent to <strong>%s</strong> but not published online.':
        'Они будут отправлены в <strong>%s</strong>, но не будут опубликованы.',
    'This cobrand is already assigned to another body: ':
        'Этот кобренд уже назначен другой организации: ',
    "This email was sent automatically, from an unmonitored email account. Please do not reply to it.":
        'Это письмо отправлено автоматически с неконтролируемого адреса. Пожалуйста, не отвечайте на него.',
    'This email was sent from a staging site.':
        'Это письмо отправлено с тестового сайта.',
    "This is a <strong>private</strong> name for this template so you can identify it when updating reports or editing in the admin.":
        'Это <strong>приватное</strong> название шаблона для его идентификации при обновлении отчётов или редактировании в админке.',
    "This is the <strong>public</strong> text that will be shown on the site.":
        'Это <strong>публичный</strong> текст, который будет показан на сайте.',
    "This is the text that will be sent to the <strong>reporting citizen</strong> in the alert email.":
        'Это текст, который будет отправлен <strong>автору отчёта</strong> в уведомительном письме.',
    "This means the user will only see front end staff features (such as the inspector form) in their assigned categories.":
        'Это означает, что пользователь увидит функции сотрудника (такие как форма инспектора) только в назначенных категориях.',
    'This page is a quick way to create many new staff users in one go.':
        'Эта страница — быстрый способ создать много новых сотрудников за раз.',
    'This report breaks the <a href="/about/house-rules">Conditions of Use</a>':
        'Этот отчёт нарушает <a href="/about/house-rules">Условия использования</a>',
    "This report is a duplicate. Please leave updates on the original report:":
        'Этот отчёт является дубликатом. Оставляйте обновления в оригинальном отчёте:',
    'This update breaks the <a href="/about/house-rules">Conditions of Use</a>':
        'Это обновление нарушает <a href="/about/house-rules">Условия использования</a>',
    "This will be the only time this token is visible, so please make a note of it now.":
        'Токен будет показан только сейчас, запишите его.',
    'To limit this collection of fields to a single cobrand, select it here.':
        'Чтобы ограничить эту группу полей одним кобрендом, выберите его здесь.',
    "To limit this collection of fields to a single language, select it here.":
        'Чтобы ограничить эту группу полей одним языком, выберите его здесь.',
    "Type in the search box to find an available category or choose from the list below.":
        'Введите в поле поиска для нахождения категории или выберите из списка ниже.',
    "Use this for issues that you want to allow users to report, but for which there is no public interest in displaying the report, like requesting an extra rubbish bin at a specific address.":
        'Используйте для проблем, которые пользователи могут сообщать, но отображение которых публично нецелесообразно, например запрос дополнительного мусорного контейнера.',
    "Use this if a category should be considered a litter category where a council is responsible for litter on a section of Highways England road":
        'Используйте, если категория должна считаться категорией мусора, где администрация отвечает за уборку на участке дороги',
    "Use this if there is a chance that multiple bodies covering the same area that have the same contacts and you want to just send reports to one, rather than multiple bodies":
        'Используйте, если несколько организаций в одном районе имеют одинаковые контакты и вы хотите отправлять отчёты только в одну из них',
    "Use this if you wish only users assigned to this category to see staff-related features (such as the inspector form) in the front end.":
        'Используйте, если вы хотите, чтобы только назначенные пользователи видели функции сотрудника в этой категории.',
    "Use this where you do not want problem reporters to be able to reopen their fixed or closed reports when leaving an update.":
        'Используйте, если вы не хотите, чтобы авторы могли повторно открывать исправленные или закрытые отчёты при обновлении.',
    "Users can be assigned one or more roles to give them all the permissions of those roles. Selecting a role or roles will disable manual permission selection.":
        'Пользователям можно назначить одну или несколько ролей. Выбор роли отключит ручной выбор разрешений.',
    "Users can perform the following actions within their assigned body or area.":
        'Пользователи могут выполнять следующие действия в рамках назначенной организации или района.',
    "Users with this role can perform the following actions within their assigned body or area.":
        'Пользователи с этой ролью могут выполнять следующие действия в рамках назначенной организации или района.',
    "We collect only the minimum amount of personal data to allow you to mange your reports. Please see our <a href=\"%s\">privacy policy</a> for more information.":
        'Мы собираем минимум персональных данных для управления отчётами. Подробнее в нашей <a href="%s">политике конфиденциальности</a>.',
    "We will only use your personal information in accordance with our <a href=\"%s\">privacy policy.</a>":
        'Мы используем ваши персональные данные только в соответствии с нашей <a href="%s">политикой конфиденциальности.</a>',
    "We won\u2019t use your email for anything beyond sending you alerts within this area. You can find more information in our <a href=\"%s\">privacy policy</a>.":
        'Мы не будем использовать вашу эл. почту ни для чего, кроме отправки оповещений по этому району. Подробнее в нашей <a href="%s">политике конфиденциальности</a>.',
    "We\u2019ve already reported these nearby problems to the council. Is one of them yours?":
        'Мы уже сообщили о ближайших проблемах в администрацию. Одна из них ваша?',
    "You can choose to subscribe to all problems reported in an area, or reports based on their destination.":
        'Вы можете подписаться на все проблемы в районе или на отчёты по назначению.',
    "You can do this on <a href=\"%s\">WriteToThem</a>, another useful mySociety website.":
        'Вы можете сделать это на <a href="%s">WriteToThem</a>, другом полезном сайте mySociety.',
    "You can find lots more information about FixMyStreet in <a href=\"/about/information-for-councils\">our FAQs</a>. For anything else, please <a href=\"/contact\">get in touch</a>":
        'Подробнее об InfraSignal — в <a href="/about/information-for-councils">нашем FAQ</a>. По другим вопросам <a href="/contact">свяжитесь с нами</a>',
    "You have already attached files to this report.  Note that you can attach a maximum of 3 to this report (if you try to upload more, the oldest will be removed).":
        'Вы уже прикрепили файлы к этому отчёту. Максимум — 3 файла (при загрузке дополнительных самый старый будет удалён).',
    "You have already attached photos to this update.  Note that you can attach a maximum of 3 to this update (if you try to upload more, the oldest will be removed).":
        'Вы уже прикрепили фото к этому обновлению. Максимум — 3 фото (при загрузке дополнительных самое старое будет удалено).',
    'Your donations keep this site and others like it running':
        'Ваши пожертвования помогают поддерживать этот и другие подобные сайты',
    "Your information will only be used in accordance with our <a href=\"%s\">privacy policy</a>":
        'Ваша информация будет использоваться только в соответствии с нашей <a href="%s">политикой конфиденциальности</a>',
    "Your password has expired, please create a new one below. When you click the link in your email, your password will be updated.":
        'Ваш пароль устарел, создайте новый ниже. При переходе по ссылке в письме пароль будет обновлён.',
    'Your report (%d) has had an update; to view: %s\n\nTo stop: %s':
        'Ваш отчёт (%d) обновлён; просмотр: %s\n\nОтписка: %s',
    "a colon-separated list of permissions to grant that user, e.g. <code>contribute_as_body:moderate:user_edit</code>.":
        'список разрешений через двоеточие, напр. <code>contribute_as_body:moderate:user_edit</code>.',
    "a colon-separated list of roles to assign to that user.":
        'список ролей через двоеточие для назначения пользователю.',
    "the database id of the body to associate that user with, e.g. <code>2217</code> for Buckinghamshire.":
        'ID организации в базе данных для привязки пользователя, напр. <code>2217</code>.',
    "Category changed from '%s' to '%s'":
        'Категория изменена с «%s» на «%s»',
    "Check <a href=\"/about/house-rules\" target=\"_blank\">what's acceptable</a>":
        'Проверьте <a href="/about/house-rules" target="_blank">что допустимо</a>',
    "Check you <strong>haven't swapped numbers and letters</strong>. <code>O</code>, <code>0</code>, <code>I</code> and <code>1</code> aren't the same.":
        'Убедитесь, что вы <strong>не перепутали буквы и цифры</strong>. <code>O</code>, <code>0</code>, <code>I</code> и <code>1</code> — это не одно и то же.',
    "Don't identify or accuse other&nbsp;people":
        'Не называйте и не обвиняйте&nbsp;других',
    "Don't include private contact details in the&nbsp;description":
        'Не включайте личные контактные данные в&nbsp;описание',
    "Say how long the issue's been&nbsp;present":
        'Укажите, как давно существует&nbsp;проблема',
    "If there's a better contact address for the reports you are receiving, tell us by emailing support@fixmystreet.com and we'll update it for you.":
        'Если есть лучший контактный адрес для получаемых отчётов, сообщите нам по эл. почте, и мы обновим его.',
    "If ticked, the form will be disabled and this item's notice text will be displayed.":
        'Если отмечено, форма будет отключена, и будет показан текст уведомления.',
    "If you let us know your email address, we'll notify you when this problem is updated or fixed.":
        'Если вы укажете свой адрес эл. почты, мы уведомим вас, когда проблема будет обновлена или решена.',
    "If you're <strong>not sure on the spelling</strong>, try another nearby street you <em>are</em> sure about, then trace your way back on our map.":
        'Если вы <strong>не уверены в написании</strong>, попробуйте другую ближайшую улицу, затем найдите нужное место на карте.',
    "If you've made changes, leave a note explaining what, for other admins to see.":
        'Если вы внесли изменения, оставьте пояснение для других администраторов.',
    "It looks like you're not connected to the internet right now. Don't worry, you can start a report below, save it as a draft and finish it when you're connected to the internet again. You can create multiple draft reports if you need to report more than one problem.":
        'Похоже, вы сейчас не подключены к интернету. Не волнуйтесь, вы можете начать отчёт ниже, сохранить его как черновик и завершить при подключении.',
    "Meanwhile, if you're getting nowhere, you might consider writing to your local councillor or other representative to see if they can help.":
        'Если дело не продвигается, попробуйте обратиться к местному депутату или представителю.',
    "Sorry, you don't have permission to do that. If you are the problem reporter, or a member of staff, please <a href=\"%s\">sign in</a> to view this report.":
        'У вас нет разрешения на это. Если вы автор отчёта или сотрудник, <a href="%s">войдите</a> для просмотра.',
    "FixMyStreet's code is open source. If you'd like to contribute to it, or create a version of the site in your country, find everything you need at fixmystreet.org.":
        'Код InfraSignal является открытым. Если вы хотите внести вклад или создать версию для своей страны, всё необходимое на fixmystreet.org.',
    "FixMyStreet helps you send a report to your council, but we're not responsible for fixing things. If you'd like to chase your issue, please search your inbox for the latest reply, or auto-reply from your council, and respond to that.":
        'InfraSignal помогает отправить отчёт в вашу администрацию, но мы не отвечаем за устранение. Найдите последний ответ от администрации и ответьте на него.',
    "Fill in the form below to start your report and click \u2018save draft\u2019 when you're done. For peace of mind, any information you provide here will also be saved automatically. When you're connected to the internet again, come back to finish and submit it.":
        'Заполните форму ниже и нажмите «сохранить черновик» по завершении. Информация сохранится автоматически. При подключении к интернету вернитесь для завершения.',
    "These users weren't updated.":
        'Эти пользователи не были обновлены.',
    "Existing users won't be modified.":
        'Существующие пользователи не будут изменены.',
    "We've already reported these nearby problems to the council. Is one of them yours?":
        'Мы уже сообщили о ближайших проблемах. Одна из них ваша?',
    "The role's <strong>name</strong> is used to refer to this group of permissions elsewhere in the admin.":
        '<strong>Название</strong> роли используется для ссылки на эту группу разрешений в админке.',
    "There was a problem with your login information. If you cannot remember your password, or do not have one, please fill in the 'No' section of the form.":
        'Проблема с данными для входа. Если не помните пароль, заполните раздел «Нет» в форме.',
    "There was a problem with your login information. If you cannot remember your password, or do not have one, please select 'Fill in your details manually'.":
        'Проблема с данными для входа. Если не помните пароль, выберите «Заполните данные вручную».',
    "We collect only the minimum amount of personal data to allow you to mange your reports. Please see our <a href=\"%s\">privacy policy</a> for more information.":
        'Мы собираем минимум данных для управления отчётами. Подробнее в <a href="%s">политике конфиденциальности</a>.',
    "We won't use your email for anything beyond sending you alerts within this area. You can find more information in our <a href=\"%s\">privacy policy</a>.":
        'Мы не будем использовать вашу почту ни для чего, кроме оповещений по району. Подробнее в <a href="%s">политике конфиденциальности</a>.',
    "We're sorry to hear that your problem hasn't been fixed.":
        'Нам жаль, что ваша проблема не была решена.',
    "My street problem hasn't been fixed":
        'Моя проблема не была решена',
    "Information: Filters in use. The current view is customized based on selected filters.":
        'Информация: Используются фильтры. Текущий вид настроен на основе выбранных фильтров.',
}

# Fuzzy fixes
FUZZY = {
    "Can\u2019t use the map to start a report? <a href=\"%s\" rel=\"nofollow\">Skip this step</a>":
        'Не можете использовать карту? <a href="%s" rel="nofollow">Пропустите этот шаг</a>',
    "Can't use the map to start a report? <a href=\"%s\" rel=\"nofollow\">Skip this step</a>":
        'Не можете использовать карту? <a href="%s" rel="nofollow">Пропустите этот шаг</a>',
    'Choose your password': 'Выберите пароль',
    'Click the link in our confirmation email to submit your problem.':
        'Нажмите на ссылку в нашем письме для отправки вашей проблемы.',
    'Click the link in our confirmation email to submit your update.':
        'Нажмите на ссылку в нашем письме для отправки вашего обновления.',
    'Column number:': 'Номер столбца:',
    'Confirmed: ': 'Подтверждено: ',
    'Contact email': 'Контактный email',
    'Council ref:': 'Номер в администрации:',
    'Council stats': 'Статистика администрации',
    'Create your account': 'Создать аккаунт',
    'Date range': 'Диапазон дат',
    'Details label': 'Метка деталей',
    'Donate now': 'Пожертвовать сейчас',
    'Draft report saved on %s': 'Черновик отчёта сохранён %s',
    'Draft reports': 'Черновики отчётов',
    'Editing report %d': 'Редактирование отчёта %d',
    'Failed bodies:': 'Организации с ошибкой:',
    'FixMyStreet Name': 'Название InfraSignal',
    'FixMyStreet ref:&nbsp;%s': 'InfraSignal ref:&nbsp;%s',
    'Follow a division link to view only reports within that division.':
        'Перейдите по ссылке подразделения, чтобы просмотреть только его отчёты.',
    'For councils': 'Для администраций',
    'Help support FixMyStreet': 'Поддержите InfraSignal',
    'I want to report a street problem': 'Я хочу сообщить о проблеме на улице',
    "If you are trying to make a new report, please <a href=\"/\">go to the front page</a> and follow the instructions.":
        'Если хотите создать новый отчёт, <a href="/">перейдите на главную</a> и следуйте инструкциям.',
    'Important message': 'Важное сообщение',
    'Last send fail:': 'Последняя ошибка отправки:',
    'Mark as skipped': 'Пометить как пропущенное',
    'Must not contain spaces.': 'Не должно содержать пробелов.',
    "My street problem hasn\u2019t been fixed": 'Моя проблема не была решена',
    'Nearest address to the pin placed on the map (from %s): %s':
        'Ближайший адрес к метке на карте (от %s): %s',
    'Nearest road to the pin placed on the map (automatically generated by %s): %s':
        'Ближайшая дорога к метке на карте (автоматически, %s): %s',
    'Only reports sent to %s': 'Только отчёты, отправленные в %s',
    'Only reports sent to %s, within %s ward': 'Только отчёты в %s в районе %s',
    'Photos added': 'Фото добавлены',
    'Photos deleted': 'Фото удалены',
    'Please enter a valid UK phone number': 'Пожалуйста, введите действительный номер телефона',
    'Please enter a valid postcode or area': 'Пожалуйста, введите действительный почтовый индекс или район',
    'Please select a time in the past': 'Пожалуйста, выберите время в прошлом',
    'Posted anonymously': 'Опубликовано анонимно',
    'Problems reported in area:': 'Проблемы, сообщённые в районе:',
    'Receive questionnaires': 'Получать анкеты',
    'Refused bodies': 'Отклонённые организации',
    'Report status': 'Статус отчёта',
    'Reporting message': 'Сообщение на странице отчётов',
    'Reposition report here': 'Переместить отчёт сюда',
    'Resend update': 'Повторно отправить обновление',
    'Select multiple divisions to view only reports within those divisions.':
        'Выберите несколько подразделений для просмотра только их отчётов.',
    'Send state:': 'Статус отправки:',
    'Start new report here': 'Создать новый отчёт здесь',
    'Start time': 'Время начала',
    'Statistics for council staff': 'Статистика для сотрудников',
    'Status unknown': 'Статус неизвестен',
    'Template email response:': 'Шаблон ответа по эл. почте:',
    'This field is required.': 'Это поле обязательно.',
    'This report has not been fixed': 'Этот отчёт не был исправлен',
    'Update has been marked as sent.': 'Обновление помечено как отправленное.',
    'Update will now be resent.': 'Обновление будет отправлено повторно.',
    'Use exact locations': 'Использовать точные координаты',
    'Use my location': 'Использовать моё местоположение',
    'View reports by division': 'Просмотр отчётов по подразделениям',
    'WasteWorks Configuration': 'Конфигурация WasteWorks',
    'WasteWorks Name': 'Название WasteWorks',
    "We\u2019re sorry to hear that your problem hasn\u2019t been fixed.":
        'Нам жаль, что ваша проблема не была решена.',
    'When sent:': 'Дата отправки:',
    'Where we send %s reports': 'Куда мы отправляем отчёты %s',
    'ref:&nbsp;%s': 'ref:&nbsp;%s',
    'required': 'обязательно',
    'sack subscription': 'подписка на мешки',
}

def main():
    po = polib.pofile(PO_FILE)
    t_count = 0
    f_count = 0
    skipped_t = []
    skipped_f = []

    # Fix fuzzy entries
    for entry in list(po.fuzzy_entries()):
        mid = entry.msgid
        if mid in FUZZY:
            entry.msgstr = FUZZY[mid]
            if 'fuzzy' in entry.flags:
                entry.flags.remove('fuzzy')
            f_count += 1
        elif mid in T:
            entry.msgstr = T[mid]
            if 'fuzzy' in entry.flags:
                entry.flags.remove('fuzzy')
            f_count += 1
        else:
            skipped_f.append(mid[:80])

    # Translate untranslated
    for entry in list(po.untranslated_entries()):
        mid = entry.msgid
        if mid in T:
            entry.msgstr = T[mid]
            t_count += 1
        else:
            skipped_t.append(mid[:80])

    po.save()

    po2 = polib.pofile(PO_FILE)
    print(f"Pass 3 results:")
    print(f"  Translated: {t_count}")
    print(f"  Fuzzy fixed: {f_count}")
    print(f"  Skipped untranslated: {len(skipped_t)}")
    print(f"  Skipped fuzzy: {len(skipped_f)}")
    print(f"\nFinal stats:")
    print(f"  Total: {len(po2)}")
    print(f"  Translated: {len(po2.translated_entries())}")
    print(f"  Fuzzy: {len(po2.fuzzy_entries())}")
    print(f"  Untranslated: {len(po2.untranslated_entries())}")

    if skipped_t:
        print(f"\nStill untranslated ({len(skipped_t)}):")
        for i, s in enumerate(skipped_t):
            print(f"  {i+1}. {s!r}")
    if skipped_f:
        print(f"\nStill fuzzy ({len(skipped_f)}):")
        for i, s in enumerate(skipped_f):
            print(f"  {i+1}. {s!r}")

if __name__ == '__main__':
    main()
