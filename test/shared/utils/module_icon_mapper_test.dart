import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ametoolbox/core/constants.dart';
import 'package:ametoolbox/shared/utils/module_icon_mapper.dart';

void main() {
  group('ModuleIconMapper', () {
    test('已登记名称返回专属图标', () {
      expect(ModuleIconMapper.map('shift'), Icons.calendar_month_outlined);
      expect(ModuleIconMapper.map('calculator'), Icons.calculate_outlined);
      expect(ModuleIconMapper.map('todo'), Icons.check_circle_outline);
      expect(ModuleIconMapper.map('checklist'), Icons.checklist_outlined);
      expect(ModuleIconMapper.map('notes'), Icons.sticky_note_2_outlined);
      expect(ModuleIconMapper.map('home'), Icons.home_outlined);
      expect(ModuleIconMapper.map('settings'), Icons.settings_outlined);
    });

    test('未知名称回退到占位图标', () {
      expect(ModuleIconMapper.map('unknown_icon'), Icons.extension);
      expect(ModuleIconMapper.map(''), Icons.extension);
    });

    test('defaultModules 的 iconName 均已登记（首页 / 模块管理共用同一映射）', () {
      for (final module in AppConstants.defaultModules) {
        expect(
          ModuleIconMapper.map(module.iconName),
          isNot(Icons.extension),
          reason: '模块「${module.id}」的 iconName「${module.iconName}」'
              '未在 ModuleIconMapper 登记，将显示为兜底占位图标',
        );
      }
    });
  });
}