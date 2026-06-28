#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Add translations for the 87 InfraSignal loc() strings missing from ru/tr/es
catalogs. Idempotent: updates msgstr if the entry already exists, else appends."""
import os
import polib

ROOT = "/opt/infrasignal-dev"
LOCALES = {"ru": "ru_RU", "tr": "tr_TR", "es": "es"}

# english msgid -> {ru, tr, es}
T = {
"Something went wrong": {"ru": "Что-то пошло не так", "tr": "Bir şeyler ters gitti", "es": "Algo salió mal"},
"Quick check": {"ru": "Быстрая проверка", "tr": "Hızlı kontrol", "es": "Comprobación rápida"},
"CAPTCHA verification failed": {"ru": "Проверка CAPTCHA не пройдена", "tr": "CAPTCHA doğrulaması başarısız oldu", "es": "La verificación CAPTCHA falló"},
"The CAPTCHA check did not complete. Please try the form again.": {"ru": "Проверка CAPTCHA не была завершена. Пожалуйста, попробуйте заполнить форму ещё раз.", "tr": "CAPTCHA kontrolü tamamlanmadı. Lütfen formu tekrar deneyin.", "es": "La verificación CAPTCHA no se completó. Por favor, inténtelo de nuevo con el formulario."},
"Please complete the CAPTCHA verification": {"ru": "Пожалуйста, пройдите проверку CAPTCHA", "tr": "Lütfen CAPTCHA doğrulamasını tamamlayın", "es": "Por favor, complete la verificación CAPTCHA"},
"Complete the CAPTCHA check to continue with your alert subscription.": {"ru": "Пройдите проверку CAPTCHA, чтобы продолжить подписку на оповещения.", "tr": "Uyarı aboneliğinize devam etmek için CAPTCHA kontrolünü tamamlayın.", "es": "Complete la verificación CAPTCHA para continuar con su suscripción de alertas."},
"Access blocked": {"ru": "Доступ заблокирован", "tr": "Erişim engellendi", "es": "Acceso bloqueado"},
"You do not have permission to view this": {"ru": "У вас нет прав для просмотра этой страницы", "tr": "Bunu görüntüleme izniniz yok", "es": "No tiene permiso para ver esto"},
"Page not found": {"ru": "Страница не найдена", "tr": "Sayfa bulunamadı", "es": "Página no encontrada"},
"We cannot find that page": {"ru": "Мы не можем найти эту страницу", "tr": "Bu sayfayı bulamıyoruz", "es": "No podemos encontrar esa página"},
"Return home": {"ru": "Вернуться на главную", "tr": "Ana sayfaya dön", "es": "Volver al inicio"},
"Our server hit a snag": {"ru": "На нашем сервере произошёл сбой", "tr": "Sunucumuzda bir sorun oluştu", "es": "Nuestro servidor tuvo un problema"},
"This is on our side, not yours. Please try again in a moment.": {"ru": "Это проблема на нашей стороне, а не на вашей. Пожалуйста, повторите попытку через мгновение.", "tr": "Bu sizin değil, bizim tarafımızdaki bir sorun. Lütfen birazdan tekrar deneyin.", "es": "Esto es de nuestro lado, no del suyo. Por favor, inténtelo de nuevo en un momento."},
"Help and info": {"ru": "Помощь и информация", "tr": "Yardım ve bilgi", "es": "Ayuda e información"},
"Contact us": {"ru": "Свяжитесь с нами", "tr": "Bize ulaşın", "es": "Contáctenos"},
"Still stuck?": {"ru": "Всё ещё нужна помощь?", "tr": "Hâlâ takıldınız mı?", "es": "¿Sigue sin resolverse?"},
"Our team replies within one business day.": {"ru": "Наша команда отвечает в течение одного рабочего дня.", "tr": "Ekibimiz bir iş günü içinde yanıt verir.", "es": "Nuestro equipo responde en un día hábil."},
"Verification required": {"ru": "Требуется проверка", "tr": "Doğrulama gerekli", "es": "Verificación requerida"},
"Return to the alert form, complete the CAPTCHA check, and submit again.": {"ru": "Вернитесь к форме оповещений, пройдите проверку CAPTCHA и отправьте снова.", "tr": "Uyarı formuna dönün, CAPTCHA kontrolünü tamamlayın ve tekrar gönderin.", "es": "Vuelva al formulario de alertas, complete la verificación CAPTCHA y envíelo de nuevo."},
"Go back": {"ru": "Назад", "tr": "Geri dön", "es": "Volver"},
"Read the FAQ": {"ru": "Читать частые вопросы", "tr": "SSS'yi okuyun", "es": "Leer las preguntas frecuentes"},
"Contact support": {"ru": "Связаться со службой поддержки", "tr": "Destek ile iletişime geçin", "es": "Contactar con soporte"},
"Reference code": {"ru": "Код обращения", "tr": "Referans kodu", "es": "Código de referencia"},
"Copy": {"ru": "Копировать", "tr": "Kopyala", "es": "Copiar"},
"Copied": {"ru": "Скопировано", "tr": "Kopyalandı", "es": "Copiado"},
"Copy reference code": {"ru": "Скопировать код обращения", "tr": "Referans kodunu kopyala", "es": "Copiar código de referencia"},
"As this is a staging site and %s is false, reports made on this site will be sent to the problem reporter, not the contact given for the report's category.": {"ru": "Поскольку это тестовый сайт и параметр %s имеет значение false, обращения, созданные на этом сайте, будут отправлены автору обращения, а не контакту, указанному для категории обращения.", "tr": "Bu bir hazırlık (staging) sitesi olduğundan ve %s değeri false olduğundan, bu sitede yapılan bildirimler, bildirimin kategorisi için verilen iletişim adresine değil, bildirimi yapan kişiye gönderilecektir.", "es": "Como este es un sitio de pruebas (staging) y %s es falso, los reportes realizados en este sitio se enviarán a quien los reporta, no al contacto indicado para la categoría del reporte."},
"Signed out": {"ru": "Вы вышли из системы", "tr": "Çıkış yapıldı", "es": "Sesión cerrada"},
"Session ended": {"ru": "Сеанс завершён", "tr": "Oturum sona erdi", "es": "La sesión ha finalizado"},
"Please feel free to": {"ru": "При желании вы можете", "tr": "Dilerseniz", "es": "Si lo desea, puede"},
"sign in again": {"ru": "войти снова", "tr": "tekrar giriş yapın", "es": "iniciar sesión de nuevo"},
"or go back to the": {"ru": "или вернуться на", "tr": "ya da geri dönün:", "es": "o volver a la"},
"front page": {"ru": "главную страницу", "tr": "ana sayfa", "es": "página principal"},
"Sign in again": {"ru": "Войти снова", "tr": "Tekrar giriş yap", "es": "Iniciar sesión de nuevo"},
"Back to home": {"ru": "На главную", "tr": "Ana sayfaya dön", "es": "Volver al inicio"},
"Change name": {"ru": "Изменить имя", "tr": "Adı değiştir", "es": "Cambiar nombre"},
"Add name": {"ru": "Добавить имя", "tr": "Ad ekle", "es": "Agregar nombre"},
"Back to account": {"ru": "Назад к аккаунту", "tr": "Hesaba dön", "es": "Volver a la cuenta"},
"Profile": {"ru": "Профиль", "tr": "Profil", "es": "Perfil"},
"Choose the name shown on your account and reports.": {"ru": "Выберите имя, отображаемое в вашем аккаунте и обращениях.", "tr": "Hesabınızda ve bildirimlerinizde görünen adı seçin.", "es": "Elija el nombre que se muestra en su cuenta y reportes."},
"Please enter a shorter name": {"ru": "Пожалуйста, введите более короткое имя", "tr": "Lütfen daha kısa bir ad girin", "es": "Por favor, introduzca un nombre más corto"},
"Welcome back": {"ru": "С возвращением", "tr": "Tekrar hoş geldiniz", "es": "Bienvenido de nuevo"},
"Save your reports, updates, and alert settings in one secure place.": {"ru": "Храните ваши обращения, обновления и настройки оповещений в одном защищённом месте.", "tr": "Bildirimlerinizi, güncellemelerinizi ve uyarı ayarlarınızı tek bir güvenli yerde saklayın.", "es": "Guarde sus reportes, actualizaciones y ajustes de alertas en un solo lugar seguro."},
"End-to-end encrypted reports": {"ru": "Сквозное шифрование обращений", "tr": "Uçtan uca şifreli bildirimler", "es": "Reportes cifrados de extremo a extremo"},
"Real-time municipal SLA tracking": {"ru": "Отслеживание SLA муниципалитета в реальном времени", "tr": "Gerçek zamanlı belediye SLA takibi", "es": "Seguimiento de SLA municipal en tiempo real"},
"Verified citizen-government channel": {"ru": "Проверенный канал связи между гражданами и государством", "tr": "Doğrulanmış vatandaş-devlet kanalı", "es": "Canal verificado entre ciudadanos y gobierno"},
"GovCloud-grade security": {"ru": "Безопасность уровня GovCloud", "tr": "GovCloud düzeyinde güvenlik", "es": "Seguridad de nivel GovCloud"},
"SOC 2 aligned": {"ru": "Соответствие SOC 2", "tr": "SOC 2 uyumlu", "es": "Alineado con SOC 2"},
"Account options": {"ru": "Параметры аккаунта", "tr": "Hesap seçenekleri", "es": "Opciones de cuenta"},
"Create account": {"ru": "Создать аккаунт", "tr": "Hesap oluştur", "es": "Crear cuenta"},
"Back to sign in": {"ru": "Назад ко входу", "tr": "Girişe dön", "es": "Volver a iniciar sesión"},
"Account recovery": {"ru": "Восстановление аккаунта", "tr": "Hesap kurtarma", "es": "Recuperación de cuenta"},
"Password update": {"ru": "Обновление пароля", "tr": "Parola güncelleme", "es": "Actualización de contraseña"},
"Get started": {"ru": "Начать", "tr": "Başlayın", "es": "Comenzar"},
"Enter your email and choose a new password. We will send you a secure sign-in link to confirm the change.": {"ru": "Введите ваш адрес электронной почты и выберите новый пароль. Мы отправим вам защищённую ссылку для входа, чтобы подтвердить изменение.", "tr": "E-posta adresinizi girin ve yeni bir parola seçin. Değişikliği onaylamak için size güvenli bir giriş bağlantısı göndereceğiz.", "es": "Introduzca su correo electrónico y elija una nueva contraseña. Le enviaremos un enlace de inicio de sesión seguro para confirmar el cambio."},
"Choose a new password, then confirm it with the secure link we email to you.": {"ru": "Выберите новый пароль, затем подтвердите его по защищённой ссылке, которую мы отправим вам по электронной почте.", "tr": "Yeni bir parola seçin, ardından size e-posta ile gönderdiğimiz güvenli bağlantı ile onaylayın.", "es": "Elija una nueva contraseña y luego confírmela con el enlace seguro que le enviaremos por correo electrónico."},
"Already have an account?": {"ru": "Уже есть аккаунт?", "tr": "Zaten bir hesabınız var mı?", "es": "¿Ya tiene una cuenta?"},
"New password": {"ru": "Новый пароль", "tr": "Yeni parola", "es": "Nueva contraseña"},
"%d+ characters": {"ru": "%d+ символов", "tr": "%d+ karakter", "es": "%d+ caracteres"},
"Show password": {"ru": "Показать пароль", "tr": "Parolayı göster", "es": "Mostrar contraseña"},
"Hide password": {"ru": "Скрыть пароль", "tr": "Parolayı gizle", "es": "Ocultar contraseña"},
"Sign in to manage your reports, follow updates, and stay connected with your municipality.": {"ru": "Войдите, чтобы управлять своими обращениями, следить за обновлениями и оставаться на связи с вашим муниципалитетом.", "tr": "Bildirimlerinizi yönetmek, güncellemeleri takip etmek ve belediyenizle bağlantıda kalmak için giriş yapın.", "es": "Inicie sesión para gestionar sus reportes, seguir las actualizaciones y mantenerse conectado con su municipio."},
"Sign in to InfraSignal": {"ru": "Вход в InfraSignal", "tr": "InfraSignal'e giriş yapın", "es": "Iniciar sesión en InfraSignal"},
"New here?": {"ru": "Впервые здесь?", "tr": "Yeni misiniz?", "es": "¿Es nuevo aquí?"},
"Continue with Facebook": {"ru": "Продолжить через Facebook", "tr": "Facebook ile devam et", "es": "Continuar con Facebook"},
"Continue with %s": {"ru": "Продолжить через %s", "tr": "%s ile devam et", "es": "Continuar con %s"},
"Continue with Twitter": {"ru": "Продолжить через Twitter", "tr": "Twitter ile devam et", "es": "Continuar con Twitter"},
"or continue with email": {"ru": "или продолжить с помощью электронной почты", "tr": "ya da e-posta ile devam edin", "es": "o continuar con correo electrónico"},
"New to InfraSignal?": {"ru": "Впервые в InfraSignal?", "tr": "InfraSignal'de yeni misiniz?", "es": "¿Nuevo en InfraSignal?"},
"Password": {"ru": "Пароль", "tr": "Parola", "es": "Contraseña"},
"Forgot password?": {"ru": "Забыли пароль?", "tr": "Parolanızı mı unuttunuz?", "es": "¿Olvidó su contraseña?"},
"Email me a magic sign-in link": {"ru": "Отправьте мне ссылку для входа по электронной почте", "tr": "Bana e-posta ile sihirli giriş bağlantısı gönder", "es": "Envíenme un enlace mágico de inicio de sesión por correo"},
'It\'s often quickest to <a href="%s">check our FAQs</a> and see if the answer is there.': {"ru": 'Часто быстрее всего <a href="%s">посмотреть наши частые вопросы</a> и проверить, есть ли там ответ.', "tr": 'Genellikle en hızlısı <a href="%s">sık sorulan sorularımıza bakmak</a> ve cevabın orada olup olmadığını görmektir.', "es": 'A menudo lo más rápido es <a href="%s">consultar nuestras preguntas frecuentes</a> y ver si la respuesta está allí.'},
"Have you ever reported a problem to a local authority before, or is this your first time?": {"ru": "Сообщали ли вы когда-либо о проблеме в местные органы власти ранее, или это ваш первый раз?", "tr": "Daha önce yerel bir yönetime hiç sorun bildirdiniz mi, yoksa bu ilk kez mi?", "es": "¿Ha reportado alguna vez un problema a una autoridad local, o es la primera vez?"},
"If you wish to leave a public update on the problem, please enter it here\n(please note it will not be sent to the local authority).": {"ru": "Если вы хотите оставить публичное обновление по проблеме, пожалуйста, введите его здесь\n(обратите внимание, что оно не будет отправлено в местные органы власти).", "tr": "Sorunla ilgili herkese açık bir güncelleme bırakmak isterseniz, lütfen buraya girin\n(lütfen bunun yerel yönetime gönderilmeyeceğini unutmayın).", "es": "Si desea dejar una actualización pública sobre el problema, introdúzcala aquí\n(tenga en cuenta que no se enviará a la autoridad local)."},
"Thanks, glad to hear it's been fixed! Could we just ask if you have ever reported a problem to a local authority before?": {"ru": "Спасибо, рады слышать, что проблема решена! Можем ли мы спросить, сообщали ли вы когда-либо о проблеме в местные органы власти ранее?", "tr": "Teşekkürler, sorunun çözüldüğünü duymak güzel! Daha önce yerel bir yönetime hiç sorun bildirip bildirmediğinizi sorabilir miyiz?", "es": "¡Gracias, nos alegra saber que se ha resuelto! ¿Podríamos preguntarle si alguna vez ha reportado un problema a una autoridad local?"},
"Pick the closest match below to view its reports, or try a different search.": {"ru": "Выберите наиболее подходящий вариант ниже, чтобы просмотреть его обращения, или попробуйте другой запрос.", "tr": "Bildirimlerini görüntülemek için aşağıdan en yakın eşleşmeyi seçin ya da farklı bir arama deneyin.", "es": "Elija la coincidencia más cercana a continuación para ver sus reportes, o pruebe con otra búsqueda."},
"e.g. '1600 Pennsylvania Ave, Washington DC' or 'Times Square, New York'": {"ru": "напр. «1600 Pennsylvania Ave, Washington DC» или «Times Square, New York»", "tr": "örn. '1600 Pennsylvania Ave, Washington DC' veya 'Times Square, New York'", "es": "p. ej. '1600 Pennsylvania Ave, Washington DC' o 'Times Square, New York'"},
"Ref:&nbsp;%s": {"ru": "Номер:&nbsp;%s", "tr": "Referans:&nbsp;%s", "es": "Ref.:&nbsp;%s"},
"InfraSignal ref:&nbsp;%s": {"ru": "Номер InfraSignal:&nbsp;%s", "tr": "InfraSignal referansı:&nbsp;%s", "es": "Ref. de InfraSignal:&nbsp;%s"},
"Responsible Authority:": {"ru": "Ответственный орган:", "tr": "Sorumlu yönetim:", "es": "Autoridad responsable:"},
"(not sent to local authority)": {"ru": "(не отправлено в местные органы власти)", "tr": "(yerel yönetime gönderilmedi)", "es": "(no enviado a la autoridad local)"},
"Not reported to local authority": {"ru": "Не отправлено в местные органы власти", "tr": "Yerel yönetime bildirilmedi", "es": "No reportado a la autoridad local"},
"the local authority": {"ru": "местные органы власти", "tr": "yerel yönetim", "es": "la autoridad local"},
"If you let us know your email address, we'll notify you when this problem is updated or fixed.": {"ru": "Если вы сообщите нам свой адрес электронной почты, мы уведомим вас, когда эта проблема будет обновлена или решена.", "tr": "E-posta adresinizi bize bildirirseniz, bu sorun güncellendiğinde veya çözüldüğünde sizi bilgilendiririz.", "es": "Si nos indica su dirección de correo electrónico, le avisaremos cuando este problema se actualice o se resuelva."},
"It's on its way to the local authority right now.": {"ru": "Прямо сейчас оно отправляется в местные органы власти.", "tr": "Şu anda yerel yönetime iletiliyor.", "es": "Ahora mismo va de camino a la autoridad local."},
"I just reported a problem on @InfraSignal": {"ru": "Я только что сообщил о проблеме на @InfraSignal", "tr": "@InfraSignal üzerinden az önce bir sorun bildirdim", "es": "Acabo de reportar un problema en @InfraSignal"},
}


def main():
    print(f"Translations defined for {len(T)} msgids\n")
    for lang, locale in LOCALES.items():
        path = os.path.join(ROOT, f"locale/{locale}.UTF-8/LC_MESSAGES/FixMyStreet.po")
        po = polib.pofile(path)
        by_id = {e.msgid: e for e in po}
        added = updated = 0
        for msgid, tr in T.items():
            val = tr[lang]
            e = by_id.get(msgid)
            if e is None:
                po.append(polib.POEntry(msgid=msgid, msgstr=val,
                          comment="InfraSignal custom UI string"))
                added += 1
            else:
                if e.msgstr != val:
                    e.msgstr = val
                    updated += 1
                if "fuzzy" in e.flags:
                    e.flags.remove("fuzzy")
        po.save(path)
        po.save_as_mofile(path[:-3] + ".mo")
        print(f"{lang}: added={added} updated={updated}  -> saved .po + .mo")


if __name__ == "__main__":
    main()
