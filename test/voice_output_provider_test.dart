import 'package:eloqia_ai/services/voice/voice_output_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'prefers a natural US English voice and never substitutes another region',
    () {
      final Map<String, String>? selected =
          DeviceVoiceOutputProvider.selectUnitedStatesVoice(
            <Map<String, String>>[
              <String, String>{
                'name': 'Google UK English Female',
                'locale': 'en-GB',
              },
              <String, String>{
                'name': 'Microsoft Aria Online (Natural)',
                'locale': 'en-US',
              },
              <String, String>{'name': 'Google US English', 'locale': 'en_US'},
              <String, String>{'name': 'Microsoft Zira', 'locale': 'en-US'},
            ],
          );

      expect(selected?['name'], 'Microsoft Aria Online (Natural)');
      expect(
        DeviceVoiceOutputProvider.selectUnitedStatesVoice(<Map<String, String>>[
          <String, String>{'name': 'Microsoft Mark', 'locale': 'en-US'},
          <String, String>{'name': 'Microsoft Zira', 'locale': 'en-US'},
          <String, String>{'name': 'Microsoft David', 'locale': 'en-US'},
        ])?['name'],
        'Microsoft Zira',
      );
      expect(
        DeviceVoiceOutputProvider.selectUnitedStatesVoice(<Map<String, String>>[
          <String, String>{
            'name': 'Google UK English Female',
            'locale': 'en-GB',
          },
          <String, String>{'name': 'English Canada', 'locale': 'en-CA'},
        ]),
        isNull,
      );
    },
  );
}
