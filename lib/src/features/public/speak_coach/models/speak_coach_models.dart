import 'package:flutter/material.dart';

class GoalSpec {
  const GoalSpec({
    required this.id,
    required this.titleTr,
    required this.titleEn,
    required this.subtitleTr,
    required this.subtitleEn,
    required this.headlineTr,
    required this.headlineEn,
    required this.supportTr,
    required this.supportEn,
    required this.icon,
  });
  final String id;
  final String titleTr;
  final String titleEn;
  final String subtitleTr;
  final String subtitleEn;
  final String headlineTr;
  final String headlineEn;
  final String supportTr;
  final String supportEn;
  final IconData icon;
}

class TodayTask {
  const TodayTask({
    required this.id,
    required this.titleTr,
    required this.titleEn,
    required this.detailTr,
    required this.detailEn,
    required this.durationLabel,
    required this.icon,
    required this.buttonTr,
    required this.buttonEn,
  });
  final String id;
  final String titleTr;
  final String titleEn;
  final String detailTr;
  final String detailEn;
  final String durationLabel;
  final IconData icon;
  final String buttonTr;
  final String buttonEn;
}

class PathStep {
  const PathStep({
    required this.title,
    required this.detail,
    required this.done,
  });
  final String title;
  final String detail;
  final bool done;
}

class StudyPack {
  const StudyPack(
    this.id,
    this.titleTr,
    this.titleEn,
    this.subtitleTr,
    this.subtitleEn,
    this.durationLabel,
    this.icon,
    this.accentColor,
    this.phrases,
    this.dialogue,
    this.note,
    this.noteEn,
  );
  final String id;
  final String titleTr;
  final String titleEn;
  final String subtitleTr;
  final String subtitleEn;
  final String durationLabel;
  final IconData icon;
  final Color accentColor;
  final List<String> phrases;
  final String dialogue;
  final String note;
  final String noteEn;
}

class ReviewCard {
  const ReviewCard(
    this.titleTr,
    this.titleEn,
    this.phrase,
    this.meaningTr,
    this.meaningEn,
    this.usageTr,
    this.usageEn,
  );
  final String titleTr;
  final String titleEn;
  final String phrase;
  final String meaningTr;
  final String meaningEn;
  final String usageTr;
  final String usageEn;
}

class PronunciationSpot {
  const PronunciationSpot(
    this.titleTr,
    this.titleEn,
    this.focusLine,
    this.helperTr,
    this.helperEn,
  );
  final String titleTr;
  final String titleEn;
  final String focusLine;
  final String helperTr;
  final String helperEn;
}

class PlannerTarget {
  const PlannerTarget(this.value, this.labelTr, this.labelEn);
  final int value;
  final String labelTr;
  final String labelEn;
}

class ScheduleSpec {
  const ScheduleSpec(this.id, this.titleTr, this.titleEn, this.detail);
  final String id;
  final String titleTr;
  final String titleEn;
  final String detail;
}

class ReminderSpec {
  const ReminderSpec(this.id, this.titleTr, this.titleEn);
  final String id;
  final String titleTr;
  final String titleEn;
}

class PracticeModeSpec {
  const PracticeModeSpec(
    this.id,
    this.titleTr,
    this.titleEn,
    this.detailTr,
    this.detailEn,
    this.icon,
    this.accentColor,
  );

  final String id;
  final String titleTr;
  final String titleEn;
  final String detailTr;
  final String detailEn;
  final IconData icon;
  final Color accentColor;
}

class CalendarDay {
  const CalendarDay({
    required this.date,
    required this.active,
    required this.isToday,
  });

  final DateTime date;
  final bool active;
  final bool isToday;
}

class ProofMetric {
  const ProofMetric({required this.value, required this.label});
  final String value;
  final String label;
}

class PlannerResult {
  const PlannerResult(this.goalId, this.scheduleId, this.weeklyTarget);
  final String goalId;
  final String scheduleId;
  final int weeklyTarget;
}

class CompletionSpec {
  const CompletionSpec({
    required this.title,
    required this.detail,
    required this.primaryLabel,
    required this.primaryAction,
    required this.secondaryLabel,
    required this.secondaryAction,
  });

  final String title;
  final String detail;
  final String primaryLabel;
  final VoidCallback primaryAction;
  final String secondaryLabel;
  final VoidCallback secondaryAction;
}

class TaskTileData {
  const TaskTileData({
    required this.title,
    required this.detail,
    required this.durationLabel,
    required this.icon,
    required this.done,
    required this.buttonLabel,
    required this.onOpen,
    required this.onToggleDone,
  });
  final String title;
  final String detail;
  final String durationLabel;
  final IconData icon;
  final bool done;
  final String buttonLabel;
  final VoidCallback onOpen;
  final VoidCallback onToggleDone;
}

class PackCardData {
  const PackCardData({
    required this.title,
    required this.subtitle,
    required this.durationLabel,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final String durationLabel;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
}

class ReviewCardData {
  const ReviewCardData({
    required this.title,
    required this.phrase,
    required this.meaning,
    required this.usage,
    required this.onTap,
  });
  final String title;
  final String phrase;
  final String meaning;
  final String usage;
  final VoidCallback onTap;
}

class TutorCardData {
  const TutorCardData({
    required this.name,
    required this.role,
    required this.imageUrl,
    required this.tags,
    required this.availabilityLabel,
    required this.ctaLabel,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
  });
  final String name;
  final String role;
  final String imageUrl;
  final List<String> tags;
  final String availabilityLabel;
  final String ctaLabel;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
}
