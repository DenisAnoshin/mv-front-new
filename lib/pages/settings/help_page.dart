import 'package:flutter/material.dart';
import '../../widgets/faq/faq_list.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = _mockGroups();
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF1F3F6),
        foregroundColor: Colors.black,
        centerTitle: false,
        title: const SizedBox.shrink(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          FaqList(groups: groups),
        ],
      ),
    );
  }

  List<FaqGroup> _mockGroups() {
    return const [
      FaqGroup(
        title: 'О приложении',
        icon: Icons.info_outline,
        items: [
          FaqItem(question: 'Что это за приложение?', answer: 'Это демонстрационный клиент с интерфейсом, похожим на мессенджер.'),
          FaqItem(question: 'Какие платформы поддерживаются?', answer: 'iOS, Android, Web, Desktop (через Flutter).'),
        ],
      ),
      FaqGroup(
        title: 'Ваш аккаунт',
        icon: Icons.person_outline,
        items: [
          FaqItem(question: 'Как изменить имя?', answer: 'Откройте Настройки → Профиль и отредактируйте имя.'),
          FaqItem(question: 'Как выйти из аккаунта?', answer: 'Настройки → Устройства → Завершить все остальные сессии.'),
        ],
      ),
      FaqGroup(
        title: 'Безопасность',
        icon: Icons.verified_user_outlined,
        items: [
          FaqItem(question: 'Есть ли двухфакторная защита?', answer: 'Да, включите её в Настройки → Приватность.'),
          FaqItem(question: 'Где хранятся данные?', answer: 'Локально в кэше и в удалённом хранилище в зашифрованном виде.'),
        ],
      ),
      FaqGroup(
        title: 'Переписка',
        icon: Icons.chat_bubble_outline,
        items: [
          FaqItem(question: 'Как закрепить чат?', answer: 'Откройте список чатов, зажмите чат и выберите «Закрепить». '),
          FaqItem(question: 'Как удалить сообщение?', answer: 'Откройте контекстное меню сообщения и выберите «Удалить». '),
        ],
      ),
      FaqGroup(
        title: 'Управление групповым чатом',
        icon: Icons.group_outlined,
        items: [
          FaqItem(question: 'Как добавить участника?', answer: 'Вверху чата нажмите на название → Добавить участника.'),
          FaqItem(question: 'Как назначить администратора?', answer: 'В параметрах группы выберите участника и включите права администратора.'),
        ],
      ),
      FaqGroup(
        title: 'Папки',
        icon: Icons.folder_outlined,
        items: [
          FaqItem(question: 'Как создать папку?', answer: 'Настройки → Папки → Создать папку.'),
          FaqItem(question: 'Как переименовать папку?', answer: 'Откройте папку, нажмите «Изменить» и измените название.'),
        ],
      ),
      FaqGroup(
        title: 'Уведомления',
        icon: Icons.notifications_outlined,
        items: [
          FaqItem(question: 'Как отключить уведомления?', answer: 'Настройки → Уведомления → выключите нужные параметры.'),
          FaqItem(question: 'Как включить превью текста?', answer: 'Включите «Показывать отправителя и текст». '),
        ],
      ),
      FaqGroup(
        title: 'Контакты',
        icon: Icons.people_outline,
        items: [
          FaqItem(question: 'Как добавить контакт?', answer: 'Перейдите в раздел «Контакты» и нажмите «Добавить». '),
          FaqItem(question: 'Как заблокировать контакт?', answer: 'Настройки → Приватность → Чёрный список.'),
        ],
      ),
    ];
  }
} 