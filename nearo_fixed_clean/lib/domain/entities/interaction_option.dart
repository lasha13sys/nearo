enum InteractionOptionType {
  meetNow,
  easyStart,
  funGame,
  leaveSocial,
  leaveNumber,
  openChat,
}

class InteractionOption {
  final String id;
  final InteractionOptionType type;
  final String title;
  final String description;
  final String icon;
  final bool enabled;
  final bool requiresMutualConsent;

  const InteractionOption({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    this.enabled = true,
    this.requiresMutualConsent = false,
  });

  factory InteractionOption.fromMap(Map<String, dynamic> map, String id) {
    return InteractionOption(
      id: id,
      type: InteractionOptionType.values.firstWhere(
        (value) => value.name == (map['type'] as String? ?? InteractionOptionType.openChat.name),
        orElse: () => InteractionOptionType.openChat,
      ),
      title: map['title'] as String? ?? 'Open Chat',
      description: map['description'] as String? ?? '',
      icon: map['icon'] as String? ?? 'chat',
      enabled: map['enabled'] as bool? ?? true,
      requiresMutualConsent: map['requiresMutualConsent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'title': title,
        'description': description,
        'icon': icon,
        'enabled': enabled,
        'requiresMutualConsent': requiresMutualConsent,
      };

  static const defaults = [
    InteractionOption(
      id: 'meet_now',
      type: InteractionOptionType.meetNow,
      title: 'Meet Now',
      description: 'Create a temporary in-venue meet intent without sharing exact location.',
      icon: 'local_fire_department',
      requiresMutualConsent: true,
    ),
    InteractionOption(
      id: 'easy_start',
      type: InteractionOptionType.easyStart,
      title: 'Easy Start',
      description: 'Open chat with low-pressure prompts.',
      icon: 'coffee',
    ),
    InteractionOption(
      id: 'fun_game',
      type: InteractionOptionType.funGame,
      title: 'Fun Game',
      description: 'Answer a quick compatibility prompt.',
      icon: 'casino',
    ),
    InteractionOption(
      id: 'leave_social',
      type: InteractionOptionType.leaveSocial,
      title: 'Leave Social',
      description: 'Request a mutual social handle reveal.',
      icon: 'phone_iphone',
      requiresMutualConsent: true,
    ),
    InteractionOption(
      id: 'leave_number',
      type: InteractionOptionType.leaveNumber,
      title: 'Leave Number',
      description: 'Request a mutual phone number reveal.',
      icon: 'call',
      requiresMutualConsent: true,
    ),
    InteractionOption(
      id: 'open_chat',
      type: InteractionOptionType.openChat,
      title: 'Open Chat',
      description: 'Start a temporary conversation.',
      icon: 'chat_bubble',
    ),
  ];
}
