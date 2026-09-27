import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

@immutable
class MemoToolbarCustomIconOption {
  const MemoToolbarCustomIconOption({
    required this.key,
    required this.label,
    required this.iconData,
  });

  final String key;
  final String label;
  final IconData iconData;
}

const kMemoToolbarDefaultCustomIconKey = 'hammer';

const kMemoToolbarCustomIconOptions = <MemoToolbarCustomIconOption>[
  MemoToolbarCustomIconOption(
    key: 'acorn',
    label: 'Acorn',
    iconData: PhosphorIconsRegular.acorn,
  ),
  MemoToolbarCustomIconOption(
    key: 'addressBook',
    label: 'Address Book',
    iconData: PhosphorIconsRegular.addressBook,
  ),
  MemoToolbarCustomIconOption(
    key: 'addressBookTabs',
    label: 'Address Book Tabs',
    iconData: PhosphorIconsRegular.addressBookTabs,
  ),
  MemoToolbarCustomIconOption(
    key: 'airTrafficControl',
    label: 'Air Traffic Control',
    iconData: PhosphorIconsRegular.airTrafficControl,
  ),
  MemoToolbarCustomIconOption(
    key: 'airplane',
    label: 'Airplane',
    iconData: PhosphorIconsRegular.airplane,
  ),
  MemoToolbarCustomIconOption(
    key: 'airplaneInFlight',
    label: 'Airplane In Flight',
    iconData: PhosphorIconsRegular.airplaneInFlight,
  ),
  MemoToolbarCustomIconOption(
    key: 'airplaneLanding',
    label: 'Airplane Landing',
    iconData: PhosphorIconsRegular.airplaneLanding,
  ),
  MemoToolbarCustomIconOption(
    key: 'airplaneTakeoff',
    label: 'Airplane Takeoff',
    iconData: PhosphorIconsRegular.airplaneTakeoff,
  ),
  MemoToolbarCustomIconOption(
    key: 'airplaneTaxiing',
    label: 'Airplane Taxiing',
    iconData: PhosphorIconsRegular.airplaneTaxiing,
  ),
  MemoToolbarCustomIconOption(
    key: 'airplaneTilt',
    label: 'Airplane Tilt',
    iconData: PhosphorIconsRegular.airplaneTilt,
  ),
  MemoToolbarCustomIconOption(
    key: 'airplay',
    label: 'Airplay',
    iconData: PhosphorIconsRegular.airplay,
  ),
  MemoToolbarCustomIconOption(
    key: 'alarm',
    label: 'Alarm',
    iconData: PhosphorIconsRegular.alarm,
  ),
  MemoToolbarCustomIconOption(
    key: 'alien',
    label: 'Alien',
    iconData: PhosphorIconsRegular.alien,
  ),
  MemoToolbarCustomIconOption(
    key: 'alignBottom',
    label: 'Align Bottom',
    iconData: PhosphorIconsRegular.alignBottom,
  ),
  MemoToolbarCustomIconOption(
    key: 'alignBottomSimple',
    label: 'Align Bottom Simple',
    iconData: PhosphorIconsRegular.alignBottomSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'alignCenterHorizontal',
    label: 'Align Center Horizontal',
    iconData: PhosphorIconsRegular.alignCenterHorizontal,
  ),
  MemoToolbarCustomIconOption(
    key: 'alignCenterVertical',
    label: 'Align Center Vertical',
    iconData: PhosphorIconsRegular.alignCenterVertical,
  ),
  MemoToolbarCustomIconOption(
    key: 'alignLeft',
    label: 'Align Left',
    iconData: PhosphorIconsRegular.alignLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'alignLeftSimple',
    label: 'Align Left Simple',
    iconData: PhosphorIconsRegular.alignLeftSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'alignRight',
    label: 'Align Right',
    iconData: PhosphorIconsRegular.alignRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'alignRightSimple',
    label: 'Align Right Simple',
    iconData: PhosphorIconsRegular.alignRightSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'alignTop',
    label: 'Align Top',
    iconData: PhosphorIconsRegular.alignTop,
  ),
  MemoToolbarCustomIconOption(
    key: 'alignTopSimple',
    label: 'Align Top Simple',
    iconData: PhosphorIconsRegular.alignTopSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'amazonLogo',
    label: 'Amazon Logo',
    iconData: PhosphorIconsRegular.amazonLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'ambulance',
    label: 'Ambulance',
    iconData: PhosphorIconsRegular.ambulance,
  ),
  MemoToolbarCustomIconOption(
    key: 'anchor',
    label: 'Anchor',
    iconData: PhosphorIconsRegular.anchor,
  ),
  MemoToolbarCustomIconOption(
    key: 'anchorSimple',
    label: 'Anchor Simple',
    iconData: PhosphorIconsRegular.anchorSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'androidLogo',
    label: 'Android Logo',
    iconData: PhosphorIconsRegular.androidLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'angle',
    label: 'Angle',
    iconData: PhosphorIconsRegular.angle,
  ),
  MemoToolbarCustomIconOption(
    key: 'angularLogo',
    label: 'Angular Logo',
    iconData: PhosphorIconsRegular.angularLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'aperture',
    label: 'Aperture',
    iconData: PhosphorIconsRegular.aperture,
  ),
  MemoToolbarCustomIconOption(
    key: 'appStoreLogo',
    label: 'App Store Logo',
    iconData: PhosphorIconsRegular.appStoreLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'appWindow',
    label: 'App Window',
    iconData: PhosphorIconsRegular.appWindow,
  ),
  MemoToolbarCustomIconOption(
    key: 'appleLogo',
    label: 'Apple Logo',
    iconData: PhosphorIconsRegular.appleLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'applePodcastsLogo',
    label: 'Apple Podcasts Logo',
    iconData: PhosphorIconsRegular.applePodcastsLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'approximateEquals',
    label: 'Approximate Equals',
    iconData: PhosphorIconsRegular.approximateEquals,
  ),
  MemoToolbarCustomIconOption(
    key: 'archive',
    label: 'Archive',
    iconData: PhosphorIconsRegular.archive,
  ),
  MemoToolbarCustomIconOption(
    key: 'armchair',
    label: 'Armchair',
    iconData: PhosphorIconsRegular.armchair,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowArcLeft',
    label: 'Arrow Arc Left',
    iconData: PhosphorIconsRegular.arrowArcLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowArcRight',
    label: 'Arrow Arc Right',
    iconData: PhosphorIconsRegular.arrowArcRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowBendDoubleUpLeft',
    label: 'Arrow Bend Double Up Left',
    iconData: PhosphorIconsRegular.arrowBendDoubleUpLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowBendDoubleUpRight',
    label: 'Arrow Bend Double Up Right',
    iconData: PhosphorIconsRegular.arrowBendDoubleUpRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowBendDownLeft',
    label: 'Arrow Bend Down Left',
    iconData: PhosphorIconsRegular.arrowBendDownLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowBendDownRight',
    label: 'Arrow Bend Down Right',
    iconData: PhosphorIconsRegular.arrowBendDownRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowBendLeftDown',
    label: 'Arrow Bend Left Down',
    iconData: PhosphorIconsRegular.arrowBendLeftDown,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowBendLeftUp',
    label: 'Arrow Bend Left Up',
    iconData: PhosphorIconsRegular.arrowBendLeftUp,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowBendRightDown',
    label: 'Arrow Bend Right Down',
    iconData: PhosphorIconsRegular.arrowBendRightDown,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowBendRightUp',
    label: 'Arrow Bend Right Up',
    iconData: PhosphorIconsRegular.arrowBendRightUp,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowBendUpLeft',
    label: 'Arrow Bend Up Left',
    iconData: PhosphorIconsRegular.arrowBendUpLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowBendUpRight',
    label: 'Arrow Bend Up Right',
    iconData: PhosphorIconsRegular.arrowBendUpRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowCircleDown',
    label: 'Arrow Circle Down',
    iconData: PhosphorIconsRegular.arrowCircleDown,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowCircleDownLeft',
    label: 'Arrow Circle Down Left',
    iconData: PhosphorIconsRegular.arrowCircleDownLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowCircleDownRight',
    label: 'Arrow Circle Down Right',
    iconData: PhosphorIconsRegular.arrowCircleDownRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowCircleLeft',
    label: 'Arrow Circle Left',
    iconData: PhosphorIconsRegular.arrowCircleLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowCircleRight',
    label: 'Arrow Circle Right',
    iconData: PhosphorIconsRegular.arrowCircleRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowCircleUp',
    label: 'Arrow Circle Up',
    iconData: PhosphorIconsRegular.arrowCircleUp,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowCircleUpLeft',
    label: 'Arrow Circle Up Left',
    iconData: PhosphorIconsRegular.arrowCircleUpLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowCircleUpRight',
    label: 'Arrow Circle Up Right',
    iconData: PhosphorIconsRegular.arrowCircleUpRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowClockwise',
    label: 'Arrow Clockwise',
    iconData: PhosphorIconsRegular.arrowClockwise,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowCounterClockwise',
    label: 'Arrow Counter Clockwise',
    iconData: PhosphorIconsRegular.arrowCounterClockwise,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowDown',
    label: 'Arrow Down',
    iconData: PhosphorIconsRegular.arrowDown,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowDownLeft',
    label: 'Arrow Down Left',
    iconData: PhosphorIconsRegular.arrowDownLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowDownRight',
    label: 'Arrow Down Right',
    iconData: PhosphorIconsRegular.arrowDownRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowElbowDownLeft',
    label: 'Arrow Elbow Down Left',
    iconData: PhosphorIconsRegular.arrowElbowDownLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowElbowDownRight',
    label: 'Arrow Elbow Down Right',
    iconData: PhosphorIconsRegular.arrowElbowDownRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowElbowLeft',
    label: 'Arrow Elbow Left',
    iconData: PhosphorIconsRegular.arrowElbowLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowElbowLeftDown',
    label: 'Arrow Elbow Left Down',
    iconData: PhosphorIconsRegular.arrowElbowLeftDown,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowElbowLeftUp',
    label: 'Arrow Elbow Left Up',
    iconData: PhosphorIconsRegular.arrowElbowLeftUp,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowElbowRight',
    label: 'Arrow Elbow Right',
    iconData: PhosphorIconsRegular.arrowElbowRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowElbowRightDown',
    label: 'Arrow Elbow Right Down',
    iconData: PhosphorIconsRegular.arrowElbowRightDown,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowElbowRightUp',
    label: 'Arrow Elbow Right Up',
    iconData: PhosphorIconsRegular.arrowElbowRightUp,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowElbowUpLeft',
    label: 'Arrow Elbow Up Left',
    iconData: PhosphorIconsRegular.arrowElbowUpLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowElbowUpRight',
    label: 'Arrow Elbow Up Right',
    iconData: PhosphorIconsRegular.arrowElbowUpRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowFatDown',
    label: 'Arrow Fat Down',
    iconData: PhosphorIconsRegular.arrowFatDown,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowFatLeft',
    label: 'Arrow Fat Left',
    iconData: PhosphorIconsRegular.arrowFatLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowFatLineDown',
    label: 'Arrow Fat Line Down',
    iconData: PhosphorIconsRegular.arrowFatLineDown,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowFatLineLeft',
    label: 'Arrow Fat Line Left',
    iconData: PhosphorIconsRegular.arrowFatLineLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowFatLineRight',
    label: 'Arrow Fat Line Right',
    iconData: PhosphorIconsRegular.arrowFatLineRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowFatLineUp',
    label: 'Arrow Fat Line Up',
    iconData: PhosphorIconsRegular.arrowFatLineUp,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowFatLinesDown',
    label: 'Arrow Fat Lines Down',
    iconData: PhosphorIconsRegular.arrowFatLinesDown,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowFatLinesLeft',
    label: 'Arrow Fat Lines Left',
    iconData: PhosphorIconsRegular.arrowFatLinesLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowFatLinesRight',
    label: 'Arrow Fat Lines Right',
    iconData: PhosphorIconsRegular.arrowFatLinesRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowFatLinesUp',
    label: 'Arrow Fat Lines Up',
    iconData: PhosphorIconsRegular.arrowFatLinesUp,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowFatRight',
    label: 'Arrow Fat Right',
    iconData: PhosphorIconsRegular.arrowFatRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowFatUp',
    label: 'Arrow Fat Up',
    iconData: PhosphorIconsRegular.arrowFatUp,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowLeft',
    label: 'Arrow Left',
    iconData: PhosphorIconsRegular.arrowLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowLineDown',
    label: 'Arrow Line Down',
    iconData: PhosphorIconsRegular.arrowLineDown,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowLineDownLeft',
    label: 'Arrow Line Down Left',
    iconData: PhosphorIconsRegular.arrowLineDownLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowLineDownRight',
    label: 'Arrow Line Down Right',
    iconData: PhosphorIconsRegular.arrowLineDownRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowLineLeft',
    label: 'Arrow Line Left',
    iconData: PhosphorIconsRegular.arrowLineLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowLineRight',
    label: 'Arrow Line Right',
    iconData: PhosphorIconsRegular.arrowLineRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowLineUp',
    label: 'Arrow Line Up',
    iconData: PhosphorIconsRegular.arrowLineUp,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowLineUpLeft',
    label: 'Arrow Line Up Left',
    iconData: PhosphorIconsRegular.arrowLineUpLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowLineUpRight',
    label: 'Arrow Line Up Right',
    iconData: PhosphorIconsRegular.arrowLineUpRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowRight',
    label: 'Arrow Right',
    iconData: PhosphorIconsRegular.arrowRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowSquareDown',
    label: 'Arrow Square Down',
    iconData: PhosphorIconsRegular.arrowSquareDown,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowSquareDownLeft',
    label: 'Arrow Square Down Left',
    iconData: PhosphorIconsRegular.arrowSquareDownLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowSquareDownRight',
    label: 'Arrow Square Down Right',
    iconData: PhosphorIconsRegular.arrowSquareDownRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowSquareIn',
    label: 'Arrow Square In',
    iconData: PhosphorIconsRegular.arrowSquareIn,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowSquareLeft',
    label: 'Arrow Square Left',
    iconData: PhosphorIconsRegular.arrowSquareLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowSquareOut',
    label: 'Arrow Square Out',
    iconData: PhosphorIconsRegular.arrowSquareOut,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowSquareRight',
    label: 'Arrow Square Right',
    iconData: PhosphorIconsRegular.arrowSquareRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowSquareUp',
    label: 'Arrow Square Up',
    iconData: PhosphorIconsRegular.arrowSquareUp,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowSquareUpLeft',
    label: 'Arrow Square Up Left',
    iconData: PhosphorIconsRegular.arrowSquareUpLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowSquareUpRight',
    label: 'Arrow Square Up Right',
    iconData: PhosphorIconsRegular.arrowSquareUpRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowUDownLeft',
    label: 'Arrow U Down Left',
    iconData: PhosphorIconsRegular.arrowUDownLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowUDownRight',
    label: 'Arrow U Down Right',
    iconData: PhosphorIconsRegular.arrowUDownRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowULeftDown',
    label: 'Arrow U Left Down',
    iconData: PhosphorIconsRegular.arrowULeftDown,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowULeftUp',
    label: 'Arrow U Left Up',
    iconData: PhosphorIconsRegular.arrowULeftUp,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowURightDown',
    label: 'Arrow U Right Down',
    iconData: PhosphorIconsRegular.arrowURightDown,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowURightUp',
    label: 'Arrow U Right Up',
    iconData: PhosphorIconsRegular.arrowURightUp,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowUUpLeft',
    label: 'Arrow U Up Left',
    iconData: PhosphorIconsRegular.arrowUUpLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowUUpRight',
    label: 'Arrow U Up Right',
    iconData: PhosphorIconsRegular.arrowUUpRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowUp',
    label: 'Arrow Up',
    iconData: PhosphorIconsRegular.arrowUp,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowUpLeft',
    label: 'Arrow Up Left',
    iconData: PhosphorIconsRegular.arrowUpLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowUpRight',
    label: 'Arrow Up Right',
    iconData: PhosphorIconsRegular.arrowUpRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowsClockwise',
    label: 'Arrows Clockwise',
    iconData: PhosphorIconsRegular.arrowsClockwise,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowsCounterClockwise',
    label: 'Arrows Counter Clockwise',
    iconData: PhosphorIconsRegular.arrowsCounterClockwise,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowsDownUp',
    label: 'Arrows Down Up',
    iconData: PhosphorIconsRegular.arrowsDownUp,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowsHorizontal',
    label: 'Arrows Horizontal',
    iconData: PhosphorIconsRegular.arrowsHorizontal,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowsIn',
    label: 'Arrows In',
    iconData: PhosphorIconsRegular.arrowsIn,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowsInCardinal',
    label: 'Arrows In Cardinal',
    iconData: PhosphorIconsRegular.arrowsInCardinal,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowsInLineHorizontal',
    label: 'Arrows In Line Horizontal',
    iconData: PhosphorIconsRegular.arrowsInLineHorizontal,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowsInLineVertical',
    label: 'Arrows In Line Vertical',
    iconData: PhosphorIconsRegular.arrowsInLineVertical,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowsInSimple',
    label: 'Arrows In Simple',
    iconData: PhosphorIconsRegular.arrowsInSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowsLeftRight',
    label: 'Arrows Left Right',
    iconData: PhosphorIconsRegular.arrowsLeftRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowsMerge',
    label: 'Arrows Merge',
    iconData: PhosphorIconsRegular.arrowsMerge,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowsOut',
    label: 'Arrows Out',
    iconData: PhosphorIconsRegular.arrowsOut,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowsOutCardinal',
    label: 'Arrows Out Cardinal',
    iconData: PhosphorIconsRegular.arrowsOutCardinal,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowsOutLineVertical',
    label: 'Arrows Out Line Vertical',
    iconData: PhosphorIconsRegular.arrowsOutLineVertical,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowsOutSimple',
    label: 'Arrows Out Simple',
    iconData: PhosphorIconsRegular.arrowsOutSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowsSplit',
    label: 'Arrows Split',
    iconData: PhosphorIconsRegular.arrowsSplit,
  ),
  MemoToolbarCustomIconOption(
    key: 'arrowsVertical',
    label: 'Arrows Vertical',
    iconData: PhosphorIconsRegular.arrowsVertical,
  ),
  MemoToolbarCustomIconOption(
    key: 'article',
    label: 'Article',
    iconData: PhosphorIconsRegular.article,
  ),
  MemoToolbarCustomIconOption(
    key: 'articleMedium',
    label: 'Article Medium',
    iconData: PhosphorIconsRegular.articleMedium,
  ),
  MemoToolbarCustomIconOption(
    key: 'articleNyTimes',
    label: 'Article Ny Times',
    iconData: PhosphorIconsRegular.articleNyTimes,
  ),
  MemoToolbarCustomIconOption(
    key: 'asclepius',
    label: 'Asclepius',
    iconData: PhosphorIconsRegular.asclepius,
  ),
  MemoToolbarCustomIconOption(
    key: 'asterisk',
    label: 'Asterisk',
    iconData: PhosphorIconsRegular.asterisk,
  ),
  MemoToolbarCustomIconOption(
    key: 'asteriskSimple',
    label: 'Asterisk Simple',
    iconData: PhosphorIconsRegular.asteriskSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'at',
    label: 'At',
    iconData: PhosphorIconsRegular.at,
  ),
  MemoToolbarCustomIconOption(
    key: 'atom',
    label: 'Atom',
    iconData: PhosphorIconsRegular.atom,
  ),
  MemoToolbarCustomIconOption(
    key: 'avocado',
    label: 'Avocado',
    iconData: PhosphorIconsRegular.avocado,
  ),
  MemoToolbarCustomIconOption(
    key: 'axe',
    label: 'Axe',
    iconData: PhosphorIconsRegular.axe,
  ),
  MemoToolbarCustomIconOption(
    key: 'baby',
    label: 'Baby',
    iconData: PhosphorIconsRegular.baby,
  ),
  MemoToolbarCustomIconOption(
    key: 'babyCarriage',
    label: 'Baby Carriage',
    iconData: PhosphorIconsRegular.babyCarriage,
  ),
  MemoToolbarCustomIconOption(
    key: 'backpack',
    label: 'Backpack',
    iconData: PhosphorIconsRegular.backpack,
  ),
  MemoToolbarCustomIconOption(
    key: 'backspace',
    label: 'Backspace',
    iconData: PhosphorIconsRegular.backspace,
  ),
  MemoToolbarCustomIconOption(
    key: 'bag',
    label: 'Bag',
    iconData: PhosphorIconsRegular.bag,
  ),
  MemoToolbarCustomIconOption(
    key: 'bagSimple',
    label: 'Bag Simple',
    iconData: PhosphorIconsRegular.bagSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'balloon',
    label: 'Balloon',
    iconData: PhosphorIconsRegular.balloon,
  ),
  MemoToolbarCustomIconOption(
    key: 'bandaids',
    label: 'Bandaids',
    iconData: PhosphorIconsRegular.bandaids,
  ),
  MemoToolbarCustomIconOption(
    key: 'bank',
    label: 'Bank',
    iconData: PhosphorIconsRegular.bank,
  ),
  MemoToolbarCustomIconOption(
    key: 'barbell',
    label: 'Barbell',
    iconData: PhosphorIconsRegular.barbell,
  ),
  MemoToolbarCustomIconOption(
    key: 'barcode',
    label: 'Barcode',
    iconData: PhosphorIconsRegular.barcode,
  ),
  MemoToolbarCustomIconOption(
    key: 'barn',
    label: 'Barn',
    iconData: PhosphorIconsRegular.barn,
  ),
  MemoToolbarCustomIconOption(
    key: 'barricade',
    label: 'Barricade',
    iconData: PhosphorIconsRegular.barricade,
  ),
  MemoToolbarCustomIconOption(
    key: 'baseball',
    label: 'Baseball',
    iconData: PhosphorIconsRegular.baseball,
  ),
  MemoToolbarCustomIconOption(
    key: 'baseballCap',
    label: 'Baseball Cap',
    iconData: PhosphorIconsRegular.baseballCap,
  ),
  MemoToolbarCustomIconOption(
    key: 'baseballHelmet',
    label: 'Baseball Helmet',
    iconData: PhosphorIconsRegular.baseballHelmet,
  ),
  MemoToolbarCustomIconOption(
    key: 'basket',
    label: 'Basket',
    iconData: PhosphorIconsRegular.basket,
  ),
  MemoToolbarCustomIconOption(
    key: 'basketball',
    label: 'Basketball',
    iconData: PhosphorIconsRegular.basketball,
  ),
  MemoToolbarCustomIconOption(
    key: 'bathtub',
    label: 'Bathtub',
    iconData: PhosphorIconsRegular.bathtub,
  ),
  MemoToolbarCustomIconOption(
    key: 'batteryCharging',
    label: 'Battery Charging',
    iconData: PhosphorIconsRegular.batteryCharging,
  ),
  MemoToolbarCustomIconOption(
    key: 'batteryEmpty',
    label: 'Battery Empty',
    iconData: PhosphorIconsRegular.batteryEmpty,
  ),
  MemoToolbarCustomIconOption(
    key: 'batteryFull',
    label: 'Battery Full',
    iconData: PhosphorIconsRegular.batteryFull,
  ),
  MemoToolbarCustomIconOption(
    key: 'batteryHigh',
    label: 'Battery High',
    iconData: PhosphorIconsRegular.batteryHigh,
  ),
  MemoToolbarCustomIconOption(
    key: 'batteryLow',
    label: 'Battery Low',
    iconData: PhosphorIconsRegular.batteryLow,
  ),
  MemoToolbarCustomIconOption(
    key: 'batteryMedium',
    label: 'Battery Medium',
    iconData: PhosphorIconsRegular.batteryMedium,
  ),
  MemoToolbarCustomIconOption(
    key: 'batteryPlus',
    label: 'Battery Plus',
    iconData: PhosphorIconsRegular.batteryPlus,
  ),
  MemoToolbarCustomIconOption(
    key: 'batteryPlusVertical',
    label: 'Battery Plus Vertical',
    iconData: PhosphorIconsRegular.batteryPlusVertical,
  ),
  MemoToolbarCustomIconOption(
    key: 'batteryVerticalEmpty',
    label: 'Battery Vertical Empty',
    iconData: PhosphorIconsRegular.batteryVerticalEmpty,
  ),
  MemoToolbarCustomIconOption(
    key: 'batteryVerticalFull',
    label: 'Battery Vertical Full',
    iconData: PhosphorIconsRegular.batteryVerticalFull,
  ),
  MemoToolbarCustomIconOption(
    key: 'batteryVerticalHigh',
    label: 'Battery Vertical High',
    iconData: PhosphorIconsRegular.batteryVerticalHigh,
  ),
  MemoToolbarCustomIconOption(
    key: 'batteryVerticalLow',
    label: 'Battery Vertical Low',
    iconData: PhosphorIconsRegular.batteryVerticalLow,
  ),
  MemoToolbarCustomIconOption(
    key: 'batteryVerticalMedium',
    label: 'Battery Vertical Medium',
    iconData: PhosphorIconsRegular.batteryVerticalMedium,
  ),
  MemoToolbarCustomIconOption(
    key: 'batteryWarning',
    label: 'Battery Warning',
    iconData: PhosphorIconsRegular.batteryWarning,
  ),
  MemoToolbarCustomIconOption(
    key: 'batteryWarningVertical',
    label: 'Battery Warning Vertical',
    iconData: PhosphorIconsRegular.batteryWarningVertical,
  ),
  MemoToolbarCustomIconOption(
    key: 'beachBall',
    label: 'Beach Ball',
    iconData: PhosphorIconsRegular.beachBall,
  ),
  MemoToolbarCustomIconOption(
    key: 'beanie',
    label: 'Beanie',
    iconData: PhosphorIconsRegular.beanie,
  ),
  MemoToolbarCustomIconOption(
    key: 'bed',
    label: 'Bed',
    iconData: PhosphorIconsRegular.bed,
  ),
  MemoToolbarCustomIconOption(
    key: 'beerBottle',
    label: 'Beer Bottle',
    iconData: PhosphorIconsRegular.beerBottle,
  ),
  MemoToolbarCustomIconOption(
    key: 'beerStein',
    label: 'Beer Stein',
    iconData: PhosphorIconsRegular.beerStein,
  ),
  MemoToolbarCustomIconOption(
    key: 'behanceLogo',
    label: 'Behance Logo',
    iconData: PhosphorIconsRegular.behanceLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'bell',
    label: 'Bell',
    iconData: PhosphorIconsRegular.bell,
  ),
  MemoToolbarCustomIconOption(
    key: 'bellRinging',
    label: 'Bell Ringing',
    iconData: PhosphorIconsRegular.bellRinging,
  ),
  MemoToolbarCustomIconOption(
    key: 'bellSimple',
    label: 'Bell Simple',
    iconData: PhosphorIconsRegular.bellSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'bellSimpleRinging',
    label: 'Bell Simple Ringing',
    iconData: PhosphorIconsRegular.bellSimpleRinging,
  ),
  MemoToolbarCustomIconOption(
    key: 'bellSimpleSlash',
    label: 'Bell Simple Slash',
    iconData: PhosphorIconsRegular.bellSimpleSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'bellSimpleZ',
    label: 'Bell Simple Z',
    iconData: PhosphorIconsRegular.bellSimpleZ,
  ),
  MemoToolbarCustomIconOption(
    key: 'bellSlash',
    label: 'Bell Slash',
    iconData: PhosphorIconsRegular.bellSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'bellZ',
    label: 'Bell Z',
    iconData: PhosphorIconsRegular.bellZ,
  ),
  MemoToolbarCustomIconOption(
    key: 'belt',
    label: 'Belt',
    iconData: PhosphorIconsRegular.belt,
  ),
  MemoToolbarCustomIconOption(
    key: 'bezierCurve',
    label: 'Bezier Curve',
    iconData: PhosphorIconsRegular.bezierCurve,
  ),
  MemoToolbarCustomIconOption(
    key: 'bicycle',
    label: 'Bicycle',
    iconData: PhosphorIconsRegular.bicycle,
  ),
  MemoToolbarCustomIconOption(
    key: 'binary',
    label: 'Binary',
    iconData: PhosphorIconsRegular.binary,
  ),
  MemoToolbarCustomIconOption(
    key: 'binoculars',
    label: 'Binoculars',
    iconData: PhosphorIconsRegular.binoculars,
  ),
  MemoToolbarCustomIconOption(
    key: 'biohazard',
    label: 'Biohazard',
    iconData: PhosphorIconsRegular.biohazard,
  ),
  MemoToolbarCustomIconOption(
    key: 'bird',
    label: 'Bird',
    iconData: PhosphorIconsRegular.bird,
  ),
  MemoToolbarCustomIconOption(
    key: 'blueprint',
    label: 'Blueprint',
    iconData: PhosphorIconsRegular.blueprint,
  ),
  MemoToolbarCustomIconOption(
    key: 'bluetooth',
    label: 'Bluetooth',
    iconData: PhosphorIconsRegular.bluetooth,
  ),
  MemoToolbarCustomIconOption(
    key: 'bluetoothConnected',
    label: 'Bluetooth Connected',
    iconData: PhosphorIconsRegular.bluetoothConnected,
  ),
  MemoToolbarCustomIconOption(
    key: 'bluetoothSlash',
    label: 'Bluetooth Slash',
    iconData: PhosphorIconsRegular.bluetoothSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'bluetoothX',
    label: 'Bluetooth X',
    iconData: PhosphorIconsRegular.bluetoothX,
  ),
  MemoToolbarCustomIconOption(
    key: 'boat',
    label: 'Boat',
    iconData: PhosphorIconsRegular.boat,
  ),
  MemoToolbarCustomIconOption(
    key: 'bomb',
    label: 'Bomb',
    iconData: PhosphorIconsRegular.bomb,
  ),
  MemoToolbarCustomIconOption(
    key: 'bone',
    label: 'Bone',
    iconData: PhosphorIconsRegular.bone,
  ),
  MemoToolbarCustomIconOption(
    key: 'book',
    label: 'Book',
    iconData: PhosphorIconsRegular.book,
  ),
  MemoToolbarCustomIconOption(
    key: 'bookBookmark',
    label: 'Book Bookmark',
    iconData: PhosphorIconsRegular.bookBookmark,
  ),
  MemoToolbarCustomIconOption(
    key: 'bookOpen',
    label: 'Book Open',
    iconData: PhosphorIconsRegular.bookOpen,
  ),
  MemoToolbarCustomIconOption(
    key: 'bookOpenText',
    label: 'Book Open Text',
    iconData: PhosphorIconsRegular.bookOpenText,
  ),
  MemoToolbarCustomIconOption(
    key: 'bookOpenUser',
    label: 'Book Open User',
    iconData: PhosphorIconsRegular.bookOpenUser,
  ),
  MemoToolbarCustomIconOption(
    key: 'bookmark',
    label: 'Bookmark',
    iconData: PhosphorIconsRegular.bookmark,
  ),
  MemoToolbarCustomIconOption(
    key: 'bookmarkSimple',
    label: 'Bookmark Simple',
    iconData: PhosphorIconsRegular.bookmarkSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'bookmarks',
    label: 'Bookmarks',
    iconData: PhosphorIconsRegular.bookmarks,
  ),
  MemoToolbarCustomIconOption(
    key: 'bookmarksSimple',
    label: 'Bookmarks Simple',
    iconData: PhosphorIconsRegular.bookmarksSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'books',
    label: 'Books',
    iconData: PhosphorIconsRegular.books,
  ),
  MemoToolbarCustomIconOption(
    key: 'boot',
    label: 'Boot',
    iconData: PhosphorIconsRegular.boot,
  ),
  MemoToolbarCustomIconOption(
    key: 'boules',
    label: 'Boules',
    iconData: PhosphorIconsRegular.boules,
  ),
  MemoToolbarCustomIconOption(
    key: 'boundingBox',
    label: 'Bounding Box',
    iconData: PhosphorIconsRegular.boundingBox,
  ),
  MemoToolbarCustomIconOption(
    key: 'bowlFood',
    label: 'Bowl Food',
    iconData: PhosphorIconsRegular.bowlFood,
  ),
  MemoToolbarCustomIconOption(
    key: 'bowlSteam',
    label: 'Bowl Steam',
    iconData: PhosphorIconsRegular.bowlSteam,
  ),
  MemoToolbarCustomIconOption(
    key: 'bowlingBall',
    label: 'Bowling Ball',
    iconData: PhosphorIconsRegular.bowlingBall,
  ),
  MemoToolbarCustomIconOption(
    key: 'boxArrowDown',
    label: 'Box Arrow Down',
    iconData: PhosphorIconsRegular.boxArrowDown,
  ),
  MemoToolbarCustomIconOption(
    key: 'boxArrowUp',
    label: 'Box Arrow Up',
    iconData: PhosphorIconsRegular.boxArrowUp,
  ),
  MemoToolbarCustomIconOption(
    key: 'boxingGlove',
    label: 'Boxing Glove',
    iconData: PhosphorIconsRegular.boxingGlove,
  ),
  MemoToolbarCustomIconOption(
    key: 'bracketsAngle',
    label: 'Brackets Angle',
    iconData: PhosphorIconsRegular.bracketsAngle,
  ),
  MemoToolbarCustomIconOption(
    key: 'bracketsCurly',
    label: 'Brackets Curly',
    iconData: PhosphorIconsRegular.bracketsCurly,
  ),
  MemoToolbarCustomIconOption(
    key: 'bracketsRound',
    label: 'Brackets Round',
    iconData: PhosphorIconsRegular.bracketsRound,
  ),
  MemoToolbarCustomIconOption(
    key: 'bracketsSquare',
    label: 'Brackets Square',
    iconData: PhosphorIconsRegular.bracketsSquare,
  ),
  MemoToolbarCustomIconOption(
    key: 'brain',
    label: 'Brain',
    iconData: PhosphorIconsRegular.brain,
  ),
  MemoToolbarCustomIconOption(
    key: 'brandy',
    label: 'Brandy',
    iconData: PhosphorIconsRegular.brandy,
  ),
  MemoToolbarCustomIconOption(
    key: 'bread',
    label: 'Bread',
    iconData: PhosphorIconsRegular.bread,
  ),
  MemoToolbarCustomIconOption(
    key: 'bridge',
    label: 'Bridge',
    iconData: PhosphorIconsRegular.bridge,
  ),
  MemoToolbarCustomIconOption(
    key: 'briefcase',
    label: 'Briefcase',
    iconData: PhosphorIconsRegular.briefcase,
  ),
  MemoToolbarCustomIconOption(
    key: 'briefcaseMetal',
    label: 'Briefcase Metal',
    iconData: PhosphorIconsRegular.briefcaseMetal,
  ),
  MemoToolbarCustomIconOption(
    key: 'broadcast',
    label: 'Broadcast',
    iconData: PhosphorIconsRegular.broadcast,
  ),
  MemoToolbarCustomIconOption(
    key: 'broom',
    label: 'Broom',
    iconData: PhosphorIconsRegular.broom,
  ),
  MemoToolbarCustomIconOption(
    key: 'browser',
    label: 'Browser',
    iconData: PhosphorIconsRegular.browser,
  ),
  MemoToolbarCustomIconOption(
    key: 'browsers',
    label: 'Browsers',
    iconData: PhosphorIconsRegular.browsers,
  ),
  MemoToolbarCustomIconOption(
    key: 'bug',
    label: 'Bug',
    iconData: PhosphorIconsRegular.bug,
  ),
  MemoToolbarCustomIconOption(
    key: 'bugBeetle',
    label: 'Bug Beetle',
    iconData: PhosphorIconsRegular.bugBeetle,
  ),
  MemoToolbarCustomIconOption(
    key: 'bugDroid',
    label: 'Bug Droid',
    iconData: PhosphorIconsRegular.bugDroid,
  ),
  MemoToolbarCustomIconOption(
    key: 'building',
    label: 'Building',
    iconData: PhosphorIconsRegular.building,
  ),
  MemoToolbarCustomIconOption(
    key: 'buildingApartment',
    label: 'Building Apartment',
    iconData: PhosphorIconsRegular.buildingApartment,
  ),
  MemoToolbarCustomIconOption(
    key: 'buildingOffice',
    label: 'Building Office',
    iconData: PhosphorIconsRegular.buildingOffice,
  ),
  MemoToolbarCustomIconOption(
    key: 'buildings',
    label: 'Buildings',
    iconData: PhosphorIconsRegular.buildings,
  ),
  MemoToolbarCustomIconOption(
    key: 'bulldozer',
    label: 'Bulldozer',
    iconData: PhosphorIconsRegular.bulldozer,
  ),
  MemoToolbarCustomIconOption(
    key: 'bus',
    label: 'Bus',
    iconData: PhosphorIconsRegular.bus,
  ),
  MemoToolbarCustomIconOption(
    key: 'butterfly',
    label: 'Butterfly',
    iconData: PhosphorIconsRegular.butterfly,
  ),
  MemoToolbarCustomIconOption(
    key: 'cableCar',
    label: 'Cable Car',
    iconData: PhosphorIconsRegular.cableCar,
  ),
  MemoToolbarCustomIconOption(
    key: 'cactus',
    label: 'Cactus',
    iconData: PhosphorIconsRegular.cactus,
  ),
  MemoToolbarCustomIconOption(
    key: 'cake',
    label: 'Cake',
    iconData: PhosphorIconsRegular.cake,
  ),
  MemoToolbarCustomIconOption(
    key: 'calculator',
    label: 'Calculator',
    iconData: PhosphorIconsRegular.calculator,
  ),
  MemoToolbarCustomIconOption(
    key: 'calendar',
    label: 'Calendar',
    iconData: PhosphorIconsRegular.calendar,
  ),
  MemoToolbarCustomIconOption(
    key: 'calendarBlank',
    label: 'Calendar Blank',
    iconData: PhosphorIconsRegular.calendarBlank,
  ),
  MemoToolbarCustomIconOption(
    key: 'calendarCheck',
    label: 'Calendar Check',
    iconData: PhosphorIconsRegular.calendarCheck,
  ),
  MemoToolbarCustomIconOption(
    key: 'calendarDot',
    label: 'Calendar Dot',
    iconData: PhosphorIconsRegular.calendarDot,
  ),
  MemoToolbarCustomIconOption(
    key: 'calendarDots',
    label: 'Calendar Dots',
    iconData: PhosphorIconsRegular.calendarDots,
  ),
  MemoToolbarCustomIconOption(
    key: 'calendarHeart',
    label: 'Calendar Heart',
    iconData: PhosphorIconsRegular.calendarHeart,
  ),
  MemoToolbarCustomIconOption(
    key: 'calendarMinus',
    label: 'Calendar Minus',
    iconData: PhosphorIconsRegular.calendarMinus,
  ),
  MemoToolbarCustomIconOption(
    key: 'calendarPlus',
    label: 'Calendar Plus',
    iconData: PhosphorIconsRegular.calendarPlus,
  ),
  MemoToolbarCustomIconOption(
    key: 'calendarSlash',
    label: 'Calendar Slash',
    iconData: PhosphorIconsRegular.calendarSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'calendarStar',
    label: 'Calendar Star',
    iconData: PhosphorIconsRegular.calendarStar,
  ),
  MemoToolbarCustomIconOption(
    key: 'calendarX',
    label: 'Calendar X',
    iconData: PhosphorIconsRegular.calendarX,
  ),
  MemoToolbarCustomIconOption(
    key: 'callBell',
    label: 'Call Bell',
    iconData: PhosphorIconsRegular.callBell,
  ),
  MemoToolbarCustomIconOption(
    key: 'camera',
    label: 'Camera',
    iconData: PhosphorIconsRegular.camera,
  ),
  MemoToolbarCustomIconOption(
    key: 'cameraPlus',
    label: 'Camera Plus',
    iconData: PhosphorIconsRegular.cameraPlus,
  ),
  MemoToolbarCustomIconOption(
    key: 'cameraRotate',
    label: 'Camera Rotate',
    iconData: PhosphorIconsRegular.cameraRotate,
  ),
  MemoToolbarCustomIconOption(
    key: 'cameraSlash',
    label: 'Camera Slash',
    iconData: PhosphorIconsRegular.cameraSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'campfire',
    label: 'Campfire',
    iconData: PhosphorIconsRegular.campfire,
  ),
  MemoToolbarCustomIconOption(
    key: 'car',
    label: 'Car',
    iconData: PhosphorIconsRegular.car,
  ),
  MemoToolbarCustomIconOption(
    key: 'carBattery',
    label: 'Car Battery',
    iconData: PhosphorIconsRegular.carBattery,
  ),
  MemoToolbarCustomIconOption(
    key: 'carProfile',
    label: 'Car Profile',
    iconData: PhosphorIconsRegular.carProfile,
  ),
  MemoToolbarCustomIconOption(
    key: 'carSimple',
    label: 'Car Simple',
    iconData: PhosphorIconsRegular.carSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'cardholder',
    label: 'Cardholder',
    iconData: PhosphorIconsRegular.cardholder,
  ),
  MemoToolbarCustomIconOption(
    key: 'cards',
    label: 'Cards',
    iconData: PhosphorIconsRegular.cards,
  ),
  MemoToolbarCustomIconOption(
    key: 'cardsThree',
    label: 'Cards Three',
    iconData: PhosphorIconsRegular.cardsThree,
  ),
  MemoToolbarCustomIconOption(
    key: 'caretCircleDoubleDown',
    label: 'Caret Circle Double Down',
    iconData: PhosphorIconsRegular.caretCircleDoubleDown,
  ),
  MemoToolbarCustomIconOption(
    key: 'caretCircleDoubleLeft',
    label: 'Caret Circle Double Left',
    iconData: PhosphorIconsRegular.caretCircleDoubleLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'caretCircleDoubleRight',
    label: 'Caret Circle Double Right',
    iconData: PhosphorIconsRegular.caretCircleDoubleRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'caretCircleDoubleUp',
    label: 'Caret Circle Double Up',
    iconData: PhosphorIconsRegular.caretCircleDoubleUp,
  ),
  MemoToolbarCustomIconOption(
    key: 'caretCircleDown',
    label: 'Caret Circle Down',
    iconData: PhosphorIconsRegular.caretCircleDown,
  ),
  MemoToolbarCustomIconOption(
    key: 'caretCircleLeft',
    label: 'Caret Circle Left',
    iconData: PhosphorIconsRegular.caretCircleLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'caretCircleRight',
    label: 'Caret Circle Right',
    iconData: PhosphorIconsRegular.caretCircleRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'caretCircleUp',
    label: 'Caret Circle Up',
    iconData: PhosphorIconsRegular.caretCircleUp,
  ),
  MemoToolbarCustomIconOption(
    key: 'caretCircleUpDown',
    label: 'Caret Circle Up Down',
    iconData: PhosphorIconsRegular.caretCircleUpDown,
  ),
  MemoToolbarCustomIconOption(
    key: 'caretDoubleDown',
    label: 'Caret Double Down',
    iconData: PhosphorIconsRegular.caretDoubleDown,
  ),
  MemoToolbarCustomIconOption(
    key: 'caretDoubleLeft',
    label: 'Caret Double Left',
    iconData: PhosphorIconsRegular.caretDoubleLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'caretDoubleRight',
    label: 'Caret Double Right',
    iconData: PhosphorIconsRegular.caretDoubleRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'caretDoubleUp',
    label: 'Caret Double Up',
    iconData: PhosphorIconsRegular.caretDoubleUp,
  ),
  MemoToolbarCustomIconOption(
    key: 'caretDown',
    label: 'Caret Down',
    iconData: PhosphorIconsRegular.caretDown,
  ),
  MemoToolbarCustomIconOption(
    key: 'caretLeft',
    label: 'Caret Left',
    iconData: PhosphorIconsRegular.caretLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'caretLineDown',
    label: 'Caret Line Down',
    iconData: PhosphorIconsRegular.caretLineDown,
  ),
  MemoToolbarCustomIconOption(
    key: 'caretLineLeft',
    label: 'Caret Line Left',
    iconData: PhosphorIconsRegular.caretLineLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'caretLineRight',
    label: 'Caret Line Right',
    iconData: PhosphorIconsRegular.caretLineRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'caretLineUp',
    label: 'Caret Line Up',
    iconData: PhosphorIconsRegular.caretLineUp,
  ),
  MemoToolbarCustomIconOption(
    key: 'caretRight',
    label: 'Caret Right',
    iconData: PhosphorIconsRegular.caretRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'caretUp',
    label: 'Caret Up',
    iconData: PhosphorIconsRegular.caretUp,
  ),
  MemoToolbarCustomIconOption(
    key: 'caretUpDown',
    label: 'Caret Up Down',
    iconData: PhosphorIconsRegular.caretUpDown,
  ),
  MemoToolbarCustomIconOption(
    key: 'carrot',
    label: 'Carrot',
    iconData: PhosphorIconsRegular.carrot,
  ),
  MemoToolbarCustomIconOption(
    key: 'cashRegister',
    label: 'Cash Register',
    iconData: PhosphorIconsRegular.cashRegister,
  ),
  MemoToolbarCustomIconOption(
    key: 'cassetteTape',
    label: 'Cassette Tape',
    iconData: PhosphorIconsRegular.cassetteTape,
  ),
  MemoToolbarCustomIconOption(
    key: 'castleTurret',
    label: 'Castle Turret',
    iconData: PhosphorIconsRegular.castleTurret,
  ),
  MemoToolbarCustomIconOption(
    key: 'cat',
    label: 'Cat',
    iconData: PhosphorIconsRegular.cat,
  ),
  MemoToolbarCustomIconOption(
    key: 'cellSignalFull',
    label: 'Cell Signal Full',
    iconData: PhosphorIconsRegular.cellSignalFull,
  ),
  MemoToolbarCustomIconOption(
    key: 'cellSignalHigh',
    label: 'Cell Signal High',
    iconData: PhosphorIconsRegular.cellSignalHigh,
  ),
  MemoToolbarCustomIconOption(
    key: 'cellSignalLow',
    label: 'Cell Signal Low',
    iconData: PhosphorIconsRegular.cellSignalLow,
  ),
  MemoToolbarCustomIconOption(
    key: 'cellSignalMedium',
    label: 'Cell Signal Medium',
    iconData: PhosphorIconsRegular.cellSignalMedium,
  ),
  MemoToolbarCustomIconOption(
    key: 'cellSignalNone',
    label: 'Cell Signal None',
    iconData: PhosphorIconsRegular.cellSignalNone,
  ),
  MemoToolbarCustomIconOption(
    key: 'cellSignalSlash',
    label: 'Cell Signal Slash',
    iconData: PhosphorIconsRegular.cellSignalSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'cellSignalX',
    label: 'Cell Signal X',
    iconData: PhosphorIconsRegular.cellSignalX,
  ),
  MemoToolbarCustomIconOption(
    key: 'cellTower',
    label: 'Cell Tower',
    iconData: PhosphorIconsRegular.cellTower,
  ),
  MemoToolbarCustomIconOption(
    key: 'certificate',
    label: 'Certificate',
    iconData: PhosphorIconsRegular.certificate,
  ),
  MemoToolbarCustomIconOption(
    key: 'chair',
    label: 'Chair',
    iconData: PhosphorIconsRegular.chair,
  ),
  MemoToolbarCustomIconOption(
    key: 'chalkboard',
    label: 'Chalkboard',
    iconData: PhosphorIconsRegular.chalkboard,
  ),
  MemoToolbarCustomIconOption(
    key: 'chalkboardSimple',
    label: 'Chalkboard Simple',
    iconData: PhosphorIconsRegular.chalkboardSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'chalkboardTeacher',
    label: 'Chalkboard Teacher',
    iconData: PhosphorIconsRegular.chalkboardTeacher,
  ),
  MemoToolbarCustomIconOption(
    key: 'champagne',
    label: 'Champagne',
    iconData: PhosphorIconsRegular.champagne,
  ),
  MemoToolbarCustomIconOption(
    key: 'chargingStation',
    label: 'Charging Station',
    iconData: PhosphorIconsRegular.chargingStation,
  ),
  MemoToolbarCustomIconOption(
    key: 'chartBar',
    label: 'Chart Bar',
    iconData: PhosphorIconsRegular.chartBar,
  ),
  MemoToolbarCustomIconOption(
    key: 'chartBarHorizontal',
    label: 'Chart Bar Horizontal',
    iconData: PhosphorIconsRegular.chartBarHorizontal,
  ),
  MemoToolbarCustomIconOption(
    key: 'chartDonut',
    label: 'Chart Donut',
    iconData: PhosphorIconsRegular.chartDonut,
  ),
  MemoToolbarCustomIconOption(
    key: 'chartLine',
    label: 'Chart Line',
    iconData: PhosphorIconsRegular.chartLine,
  ),
  MemoToolbarCustomIconOption(
    key: 'chartLineDown',
    label: 'Chart Line Down',
    iconData: PhosphorIconsRegular.chartLineDown,
  ),
  MemoToolbarCustomIconOption(
    key: 'chartLineUp',
    label: 'Chart Line Up',
    iconData: PhosphorIconsRegular.chartLineUp,
  ),
  MemoToolbarCustomIconOption(
    key: 'chartPie',
    label: 'Chart Pie',
    iconData: PhosphorIconsRegular.chartPie,
  ),
  MemoToolbarCustomIconOption(
    key: 'chartPieSlice',
    label: 'Chart Pie Slice',
    iconData: PhosphorIconsRegular.chartPieSlice,
  ),
  MemoToolbarCustomIconOption(
    key: 'chartPolar',
    label: 'Chart Polar',
    iconData: PhosphorIconsRegular.chartPolar,
  ),
  MemoToolbarCustomIconOption(
    key: 'chartScatter',
    label: 'Chart Scatter',
    iconData: PhosphorIconsRegular.chartScatter,
  ),
  MemoToolbarCustomIconOption(
    key: 'chat',
    label: 'Chat',
    iconData: PhosphorIconsRegular.chat,
  ),
  MemoToolbarCustomIconOption(
    key: 'chatCentered',
    label: 'Chat Centered',
    iconData: PhosphorIconsRegular.chatCentered,
  ),
  MemoToolbarCustomIconOption(
    key: 'chatCenteredDots',
    label: 'Chat Centered Dots',
    iconData: PhosphorIconsRegular.chatCenteredDots,
  ),
  MemoToolbarCustomIconOption(
    key: 'chatCenteredSlash',
    label: 'Chat Centered Slash',
    iconData: PhosphorIconsRegular.chatCenteredSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'chatCenteredText',
    label: 'Chat Centered Text',
    iconData: PhosphorIconsRegular.chatCenteredText,
  ),
  MemoToolbarCustomIconOption(
    key: 'chatCircle',
    label: 'Chat Circle',
    iconData: PhosphorIconsRegular.chatCircle,
  ),
  MemoToolbarCustomIconOption(
    key: 'chatCircleDots',
    label: 'Chat Circle Dots',
    iconData: PhosphorIconsRegular.chatCircleDots,
  ),
  MemoToolbarCustomIconOption(
    key: 'chatCircleSlash',
    label: 'Chat Circle Slash',
    iconData: PhosphorIconsRegular.chatCircleSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'chatCircleText',
    label: 'Chat Circle Text',
    iconData: PhosphorIconsRegular.chatCircleText,
  ),
  MemoToolbarCustomIconOption(
    key: 'chatDots',
    label: 'Chat Dots',
    iconData: PhosphorIconsRegular.chatDots,
  ),
  MemoToolbarCustomIconOption(
    key: 'chatSlash',
    label: 'Chat Slash',
    iconData: PhosphorIconsRegular.chatSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'chatTeardrop',
    label: 'Chat Teardrop',
    iconData: PhosphorIconsRegular.chatTeardrop,
  ),
  MemoToolbarCustomIconOption(
    key: 'chatTeardropDots',
    label: 'Chat Teardrop Dots',
    iconData: PhosphorIconsRegular.chatTeardropDots,
  ),
  MemoToolbarCustomIconOption(
    key: 'chatTeardropSlash',
    label: 'Chat Teardrop Slash',
    iconData: PhosphorIconsRegular.chatTeardropSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'chatTeardropText',
    label: 'Chat Teardrop Text',
    iconData: PhosphorIconsRegular.chatTeardropText,
  ),
  MemoToolbarCustomIconOption(
    key: 'chatText',
    label: 'Chat Text',
    iconData: PhosphorIconsRegular.chatText,
  ),
  MemoToolbarCustomIconOption(
    key: 'chats',
    label: 'Chats',
    iconData: PhosphorIconsRegular.chats,
  ),
  MemoToolbarCustomIconOption(
    key: 'chatsCircle',
    label: 'Chats Circle',
    iconData: PhosphorIconsRegular.chatsCircle,
  ),
  MemoToolbarCustomIconOption(
    key: 'chatsTeardrop',
    label: 'Chats Teardrop',
    iconData: PhosphorIconsRegular.chatsTeardrop,
  ),
  MemoToolbarCustomIconOption(
    key: 'check',
    label: 'Check',
    iconData: PhosphorIconsRegular.check,
  ),
  MemoToolbarCustomIconOption(
    key: 'checkCircle',
    label: 'Check Circle',
    iconData: PhosphorIconsRegular.checkCircle,
  ),
  MemoToolbarCustomIconOption(
    key: 'checkFat',
    label: 'Check Fat',
    iconData: PhosphorIconsRegular.checkFat,
  ),
  MemoToolbarCustomIconOption(
    key: 'checkSquare',
    label: 'Check Square',
    iconData: PhosphorIconsRegular.checkSquare,
  ),
  MemoToolbarCustomIconOption(
    key: 'checkSquareOffset',
    label: 'Check Square Offset',
    iconData: PhosphorIconsRegular.checkSquareOffset,
  ),
  MemoToolbarCustomIconOption(
    key: 'checkerboard',
    label: 'Checkerboard',
    iconData: PhosphorIconsRegular.checkerboard,
  ),
  MemoToolbarCustomIconOption(
    key: 'checks',
    label: 'Checks',
    iconData: PhosphorIconsRegular.checks,
  ),
  MemoToolbarCustomIconOption(
    key: 'cheers',
    label: 'Cheers',
    iconData: PhosphorIconsRegular.cheers,
  ),
  MemoToolbarCustomIconOption(
    key: 'cheese',
    label: 'Cheese',
    iconData: PhosphorIconsRegular.cheese,
  ),
  MemoToolbarCustomIconOption(
    key: 'chefHat',
    label: 'Chef Hat',
    iconData: PhosphorIconsRegular.chefHat,
  ),
  MemoToolbarCustomIconOption(
    key: 'cherries',
    label: 'Cherries',
    iconData: PhosphorIconsRegular.cherries,
  ),
  MemoToolbarCustomIconOption(
    key: 'church',
    label: 'Church',
    iconData: PhosphorIconsRegular.church,
  ),
  MemoToolbarCustomIconOption(
    key: 'cigarette',
    label: 'Cigarette',
    iconData: PhosphorIconsRegular.cigarette,
  ),
  MemoToolbarCustomIconOption(
    key: 'cigaretteSlash',
    label: 'Cigarette Slash',
    iconData: PhosphorIconsRegular.cigaretteSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'circle',
    label: 'Circle',
    iconData: PhosphorIconsRegular.circle,
  ),
  MemoToolbarCustomIconOption(
    key: 'circleDashed',
    label: 'Circle Dashed',
    iconData: PhosphorIconsRegular.circleDashed,
  ),
  MemoToolbarCustomIconOption(
    key: 'circleHalf',
    label: 'Circle Half',
    iconData: PhosphorIconsRegular.circleHalf,
  ),
  MemoToolbarCustomIconOption(
    key: 'circleHalfTilt',
    label: 'Circle Half Tilt',
    iconData: PhosphorIconsRegular.circleHalfTilt,
  ),
  MemoToolbarCustomIconOption(
    key: 'circleNotch',
    label: 'Circle Notch',
    iconData: PhosphorIconsRegular.circleNotch,
  ),
  MemoToolbarCustomIconOption(
    key: 'circlesFour',
    label: 'Circles Four',
    iconData: PhosphorIconsRegular.circlesFour,
  ),
  MemoToolbarCustomIconOption(
    key: 'circlesThree',
    label: 'Circles Three',
    iconData: PhosphorIconsRegular.circlesThree,
  ),
  MemoToolbarCustomIconOption(
    key: 'circlesThreePlus',
    label: 'Circles Three Plus',
    iconData: PhosphorIconsRegular.circlesThreePlus,
  ),
  MemoToolbarCustomIconOption(
    key: 'circuitry',
    label: 'Circuitry',
    iconData: PhosphorIconsRegular.circuitry,
  ),
  MemoToolbarCustomIconOption(
    key: 'city',
    label: 'City',
    iconData: PhosphorIconsRegular.city,
  ),
  MemoToolbarCustomIconOption(
    key: 'clipboard',
    label: 'Clipboard',
    iconData: PhosphorIconsRegular.clipboard,
  ),
  MemoToolbarCustomIconOption(
    key: 'clipboardText',
    label: 'Clipboard Text',
    iconData: PhosphorIconsRegular.clipboardText,
  ),
  MemoToolbarCustomIconOption(
    key: 'clock',
    label: 'Clock',
    iconData: PhosphorIconsRegular.clock,
  ),
  MemoToolbarCustomIconOption(
    key: 'clockAfternoon',
    label: 'Clock Afternoon',
    iconData: PhosphorIconsRegular.clockAfternoon,
  ),
  MemoToolbarCustomIconOption(
    key: 'clockClockwise',
    label: 'Clock Clockwise',
    iconData: PhosphorIconsRegular.clockClockwise,
  ),
  MemoToolbarCustomIconOption(
    key: 'clockCountdown',
    label: 'Clock Countdown',
    iconData: PhosphorIconsRegular.clockCountdown,
  ),
  MemoToolbarCustomIconOption(
    key: 'clockCounterClockwise',
    label: 'Clock Counter Clockwise',
    iconData: PhosphorIconsRegular.clockCounterClockwise,
  ),
  MemoToolbarCustomIconOption(
    key: 'clockUser',
    label: 'Clock User',
    iconData: PhosphorIconsRegular.clockUser,
  ),
  MemoToolbarCustomIconOption(
    key: 'closedCaptioning',
    label: 'Closed Captioning',
    iconData: PhosphorIconsRegular.closedCaptioning,
  ),
  MemoToolbarCustomIconOption(
    key: 'cloud',
    label: 'Cloud',
    iconData: PhosphorIconsRegular.cloud,
  ),
  MemoToolbarCustomIconOption(
    key: 'cloudArrowDown',
    label: 'Cloud Arrow Down',
    iconData: PhosphorIconsRegular.cloudArrowDown,
  ),
  MemoToolbarCustomIconOption(
    key: 'cloudArrowUp',
    label: 'Cloud Arrow Up',
    iconData: PhosphorIconsRegular.cloudArrowUp,
  ),
  MemoToolbarCustomIconOption(
    key: 'cloudCheck',
    label: 'Cloud Check',
    iconData: PhosphorIconsRegular.cloudCheck,
  ),
  MemoToolbarCustomIconOption(
    key: 'cloudFog',
    label: 'Cloud Fog',
    iconData: PhosphorIconsRegular.cloudFog,
  ),
  MemoToolbarCustomIconOption(
    key: 'cloudLightning',
    label: 'Cloud Lightning',
    iconData: PhosphorIconsRegular.cloudLightning,
  ),
  MemoToolbarCustomIconOption(
    key: 'cloudMoon',
    label: 'Cloud Moon',
    iconData: PhosphorIconsRegular.cloudMoon,
  ),
  MemoToolbarCustomIconOption(
    key: 'cloudRain',
    label: 'Cloud Rain',
    iconData: PhosphorIconsRegular.cloudRain,
  ),
  MemoToolbarCustomIconOption(
    key: 'cloudSlash',
    label: 'Cloud Slash',
    iconData: PhosphorIconsRegular.cloudSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'cloudSnow',
    label: 'Cloud Snow',
    iconData: PhosphorIconsRegular.cloudSnow,
  ),
  MemoToolbarCustomIconOption(
    key: 'cloudSun',
    label: 'Cloud Sun',
    iconData: PhosphorIconsRegular.cloudSun,
  ),
  MemoToolbarCustomIconOption(
    key: 'cloudWarning',
    label: 'Cloud Warning',
    iconData: PhosphorIconsRegular.cloudWarning,
  ),
  MemoToolbarCustomIconOption(
    key: 'cloudX',
    label: 'Cloud X',
    iconData: PhosphorIconsRegular.cloudX,
  ),
  MemoToolbarCustomIconOption(
    key: 'clover',
    label: 'Clover',
    iconData: PhosphorIconsRegular.clover,
  ),
  MemoToolbarCustomIconOption(
    key: 'club',
    label: 'Club',
    iconData: PhosphorIconsRegular.club,
  ),
  MemoToolbarCustomIconOption(
    key: 'coatHanger',
    label: 'Coat Hanger',
    iconData: PhosphorIconsRegular.coatHanger,
  ),
  MemoToolbarCustomIconOption(
    key: 'codaLogo',
    label: 'Coda Logo',
    iconData: PhosphorIconsRegular.codaLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'code',
    label: 'Code',
    iconData: PhosphorIconsRegular.code,
  ),
  MemoToolbarCustomIconOption(
    key: 'codeBlock',
    label: 'Code Block',
    iconData: PhosphorIconsRegular.codeBlock,
  ),
  MemoToolbarCustomIconOption(
    key: 'codeSimple',
    label: 'Code Simple',
    iconData: PhosphorIconsRegular.codeSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'codepenLogo',
    label: 'Codepen Logo',
    iconData: PhosphorIconsRegular.codepenLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'codesandboxLogo',
    label: 'Codesandbox Logo',
    iconData: PhosphorIconsRegular.codesandboxLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'coffee',
    label: 'Coffee',
    iconData: PhosphorIconsRegular.coffee,
  ),
  MemoToolbarCustomIconOption(
    key: 'coffeeBean',
    label: 'Coffee Bean',
    iconData: PhosphorIconsRegular.coffeeBean,
  ),
  MemoToolbarCustomIconOption(
    key: 'coin',
    label: 'Coin',
    iconData: PhosphorIconsRegular.coin,
  ),
  MemoToolbarCustomIconOption(
    key: 'coinVertical',
    label: 'Coin Vertical',
    iconData: PhosphorIconsRegular.coinVertical,
  ),
  MemoToolbarCustomIconOption(
    key: 'coins',
    label: 'Coins',
    iconData: PhosphorIconsRegular.coins,
  ),
  MemoToolbarCustomIconOption(
    key: 'columns',
    label: 'Columns',
    iconData: PhosphorIconsRegular.columns,
  ),
  MemoToolbarCustomIconOption(
    key: 'columnsPlusLeft',
    label: 'Columns Plus Left',
    iconData: PhosphorIconsRegular.columnsPlusLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'columnsPlusRight',
    label: 'Columns Plus Right',
    iconData: PhosphorIconsRegular.columnsPlusRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'command',
    label: 'Command',
    iconData: PhosphorIconsRegular.command,
  ),
  MemoToolbarCustomIconOption(
    key: 'compass',
    label: 'Compass',
    iconData: PhosphorIconsRegular.compass,
  ),
  MemoToolbarCustomIconOption(
    key: 'compassRose',
    label: 'Compass Rose',
    iconData: PhosphorIconsRegular.compassRose,
  ),
  MemoToolbarCustomIconOption(
    key: 'compassTool',
    label: 'Compass Tool',
    iconData: PhosphorIconsRegular.compassTool,
  ),
  MemoToolbarCustomIconOption(
    key: 'computerTower',
    label: 'Computer Tower',
    iconData: PhosphorIconsRegular.computerTower,
  ),
  MemoToolbarCustomIconOption(
    key: 'confetti',
    label: 'Confetti',
    iconData: PhosphorIconsRegular.confetti,
  ),
  MemoToolbarCustomIconOption(
    key: 'contactlessPayment',
    label: 'Contactless Payment',
    iconData: PhosphorIconsRegular.contactlessPayment,
  ),
  MemoToolbarCustomIconOption(
    key: 'control',
    label: 'Control',
    iconData: PhosphorIconsRegular.control,
  ),
  MemoToolbarCustomIconOption(
    key: 'cookie',
    label: 'Cookie',
    iconData: PhosphorIconsRegular.cookie,
  ),
  MemoToolbarCustomIconOption(
    key: 'cookingPot',
    label: 'Cooking Pot',
    iconData: PhosphorIconsRegular.cookingPot,
  ),
  MemoToolbarCustomIconOption(
    key: 'copy',
    label: 'Copy',
    iconData: PhosphorIconsRegular.copy,
  ),
  MemoToolbarCustomIconOption(
    key: 'copySimple',
    label: 'Copy Simple',
    iconData: PhosphorIconsRegular.copySimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'copyleft',
    label: 'Copyleft',
    iconData: PhosphorIconsRegular.copyleft,
  ),
  MemoToolbarCustomIconOption(
    key: 'copyright',
    label: 'Copyright',
    iconData: PhosphorIconsRegular.copyright,
  ),
  MemoToolbarCustomIconOption(
    key: 'cornersIn',
    label: 'Corners In',
    iconData: PhosphorIconsRegular.cornersIn,
  ),
  MemoToolbarCustomIconOption(
    key: 'cornersOut',
    label: 'Corners Out',
    iconData: PhosphorIconsRegular.cornersOut,
  ),
  MemoToolbarCustomIconOption(
    key: 'couch',
    label: 'Couch',
    iconData: PhosphorIconsRegular.couch,
  ),
  MemoToolbarCustomIconOption(
    key: 'courtBasketball',
    label: 'Court Basketball',
    iconData: PhosphorIconsRegular.courtBasketball,
  ),
  MemoToolbarCustomIconOption(
    key: 'cow',
    label: 'Cow',
    iconData: PhosphorIconsRegular.cow,
  ),
  MemoToolbarCustomIconOption(
    key: 'cowboyHat',
    label: 'Cowboy Hat',
    iconData: PhosphorIconsRegular.cowboyHat,
  ),
  MemoToolbarCustomIconOption(
    key: 'cpu',
    label: 'Cpu',
    iconData: PhosphorIconsRegular.cpu,
  ),
  MemoToolbarCustomIconOption(
    key: 'crane',
    label: 'Crane',
    iconData: PhosphorIconsRegular.crane,
  ),
  MemoToolbarCustomIconOption(
    key: 'craneTower',
    label: 'Crane Tower',
    iconData: PhosphorIconsRegular.craneTower,
  ),
  MemoToolbarCustomIconOption(
    key: 'creditCard',
    label: 'Credit Card',
    iconData: PhosphorIconsRegular.creditCard,
  ),
  MemoToolbarCustomIconOption(
    key: 'cricket',
    label: 'Cricket',
    iconData: PhosphorIconsRegular.cricket,
  ),
  MemoToolbarCustomIconOption(
    key: 'crop',
    label: 'Crop',
    iconData: PhosphorIconsRegular.crop,
  ),
  MemoToolbarCustomIconOption(
    key: 'cross',
    label: 'Cross',
    iconData: PhosphorIconsRegular.cross,
  ),
  MemoToolbarCustomIconOption(
    key: 'crosshair',
    label: 'Crosshair',
    iconData: PhosphorIconsRegular.crosshair,
  ),
  MemoToolbarCustomIconOption(
    key: 'crosshairSimple',
    label: 'Crosshair Simple',
    iconData: PhosphorIconsRegular.crosshairSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'crown',
    label: 'Crown',
    iconData: PhosphorIconsRegular.crown,
  ),
  MemoToolbarCustomIconOption(
    key: 'crownCross',
    label: 'Crown Cross',
    iconData: PhosphorIconsRegular.crownCross,
  ),
  MemoToolbarCustomIconOption(
    key: 'crownSimple',
    label: 'Crown Simple',
    iconData: PhosphorIconsRegular.crownSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'cube',
    label: 'Cube',
    iconData: PhosphorIconsRegular.cube,
  ),
  MemoToolbarCustomIconOption(
    key: 'cubeFocus',
    label: 'Cube Focus',
    iconData: PhosphorIconsRegular.cubeFocus,
  ),
  MemoToolbarCustomIconOption(
    key: 'cubeTransparent',
    label: 'Cube Transparent',
    iconData: PhosphorIconsRegular.cubeTransparent,
  ),
  MemoToolbarCustomIconOption(
    key: 'currencyBtc',
    label: 'Currency Btc',
    iconData: PhosphorIconsRegular.currencyBtc,
  ),
  MemoToolbarCustomIconOption(
    key: 'currencyCircleDollar',
    label: 'Currency Circle Dollar',
    iconData: PhosphorIconsRegular.currencyCircleDollar,
  ),
  MemoToolbarCustomIconOption(
    key: 'currencyCny',
    label: 'Currency Cny',
    iconData: PhosphorIconsRegular.currencyCny,
  ),
  MemoToolbarCustomIconOption(
    key: 'currencyDollar',
    label: 'Currency Dollar',
    iconData: PhosphorIconsRegular.currencyDollar,
  ),
  MemoToolbarCustomIconOption(
    key: 'currencyDollarSimple',
    label: 'Currency Dollar Simple',
    iconData: PhosphorIconsRegular.currencyDollarSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'currencyEth',
    label: 'Currency Eth',
    iconData: PhosphorIconsRegular.currencyEth,
  ),
  MemoToolbarCustomIconOption(
    key: 'currencyEur',
    label: 'Currency Eur',
    iconData: PhosphorIconsRegular.currencyEur,
  ),
  MemoToolbarCustomIconOption(
    key: 'currencyGbp',
    label: 'Currency Gbp',
    iconData: PhosphorIconsRegular.currencyGbp,
  ),
  MemoToolbarCustomIconOption(
    key: 'currencyInr',
    label: 'Currency Inr',
    iconData: PhosphorIconsRegular.currencyInr,
  ),
  MemoToolbarCustomIconOption(
    key: 'currencyJpy',
    label: 'Currency Jpy',
    iconData: PhosphorIconsRegular.currencyJpy,
  ),
  MemoToolbarCustomIconOption(
    key: 'currencyKrw',
    label: 'Currency Krw',
    iconData: PhosphorIconsRegular.currencyKrw,
  ),
  MemoToolbarCustomIconOption(
    key: 'currencyKzt',
    label: 'Currency Kzt',
    iconData: PhosphorIconsRegular.currencyKzt,
  ),
  MemoToolbarCustomIconOption(
    key: 'currencyNgn',
    label: 'Currency Ngn',
    iconData: PhosphorIconsRegular.currencyNgn,
  ),
  MemoToolbarCustomIconOption(
    key: 'currencyRub',
    label: 'Currency Rub',
    iconData: PhosphorIconsRegular.currencyRub,
  ),
  MemoToolbarCustomIconOption(
    key: 'cursor',
    label: 'Cursor',
    iconData: PhosphorIconsRegular.cursor,
  ),
  MemoToolbarCustomIconOption(
    key: 'cursorClick',
    label: 'Cursor Click',
    iconData: PhosphorIconsRegular.cursorClick,
  ),
  MemoToolbarCustomIconOption(
    key: 'cursorText',
    label: 'Cursor Text',
    iconData: PhosphorIconsRegular.cursorText,
  ),
  MemoToolbarCustomIconOption(
    key: 'cylinder',
    label: 'Cylinder',
    iconData: PhosphorIconsRegular.cylinder,
  ),
  MemoToolbarCustomIconOption(
    key: 'database',
    label: 'Database',
    iconData: PhosphorIconsRegular.database,
  ),
  MemoToolbarCustomIconOption(
    key: 'desk',
    label: 'Desk',
    iconData: PhosphorIconsRegular.desk,
  ),
  MemoToolbarCustomIconOption(
    key: 'desktop',
    label: 'Desktop',
    iconData: PhosphorIconsRegular.desktop,
  ),
  MemoToolbarCustomIconOption(
    key: 'desktopTower',
    label: 'Desktop Tower',
    iconData: PhosphorIconsRegular.desktopTower,
  ),
  MemoToolbarCustomIconOption(
    key: 'detective',
    label: 'Detective',
    iconData: PhosphorIconsRegular.detective,
  ),
  MemoToolbarCustomIconOption(
    key: 'devToLogo',
    label: 'Dev To Logo',
    iconData: PhosphorIconsRegular.devToLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'deviceMobile',
    label: 'Device Mobile',
    iconData: PhosphorIconsRegular.deviceMobile,
  ),
  MemoToolbarCustomIconOption(
    key: 'deviceMobileCamera',
    label: 'Device Mobile Camera',
    iconData: PhosphorIconsRegular.deviceMobileCamera,
  ),
  MemoToolbarCustomIconOption(
    key: 'deviceMobileSlash',
    label: 'Device Mobile Slash',
    iconData: PhosphorIconsRegular.deviceMobileSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'deviceMobileSpeaker',
    label: 'Device Mobile Speaker',
    iconData: PhosphorIconsRegular.deviceMobileSpeaker,
  ),
  MemoToolbarCustomIconOption(
    key: 'deviceRotate',
    label: 'Device Rotate',
    iconData: PhosphorIconsRegular.deviceRotate,
  ),
  MemoToolbarCustomIconOption(
    key: 'deviceTablet',
    label: 'Device Tablet',
    iconData: PhosphorIconsRegular.deviceTablet,
  ),
  MemoToolbarCustomIconOption(
    key: 'deviceTabletCamera',
    label: 'Device Tablet Camera',
    iconData: PhosphorIconsRegular.deviceTabletCamera,
  ),
  MemoToolbarCustomIconOption(
    key: 'deviceTabletSpeaker',
    label: 'Device Tablet Speaker',
    iconData: PhosphorIconsRegular.deviceTabletSpeaker,
  ),
  MemoToolbarCustomIconOption(
    key: 'devices',
    label: 'Devices',
    iconData: PhosphorIconsRegular.devices,
  ),
  MemoToolbarCustomIconOption(
    key: 'diamond',
    label: 'Diamond',
    iconData: PhosphorIconsRegular.diamond,
  ),
  MemoToolbarCustomIconOption(
    key: 'diamondsFour',
    label: 'Diamonds Four',
    iconData: PhosphorIconsRegular.diamondsFour,
  ),
  MemoToolbarCustomIconOption(
    key: 'diceFive',
    label: 'Dice Five',
    iconData: PhosphorIconsRegular.diceFive,
  ),
  MemoToolbarCustomIconOption(
    key: 'diceFour',
    label: 'Dice Four',
    iconData: PhosphorIconsRegular.diceFour,
  ),
  MemoToolbarCustomIconOption(
    key: 'diceOne',
    label: 'Dice One',
    iconData: PhosphorIconsRegular.diceOne,
  ),
  MemoToolbarCustomIconOption(
    key: 'diceSix',
    label: 'Dice Six',
    iconData: PhosphorIconsRegular.diceSix,
  ),
  MemoToolbarCustomIconOption(
    key: 'diceThree',
    label: 'Dice Three',
    iconData: PhosphorIconsRegular.diceThree,
  ),
  MemoToolbarCustomIconOption(
    key: 'diceTwo',
    label: 'Dice Two',
    iconData: PhosphorIconsRegular.diceTwo,
  ),
  MemoToolbarCustomIconOption(
    key: 'disc',
    label: 'Disc',
    iconData: PhosphorIconsRegular.disc,
  ),
  MemoToolbarCustomIconOption(
    key: 'discoBall',
    label: 'Disco Ball',
    iconData: PhosphorIconsRegular.discoBall,
  ),
  MemoToolbarCustomIconOption(
    key: 'discordLogo',
    label: 'Discord Logo',
    iconData: PhosphorIconsRegular.discordLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'divide',
    label: 'Divide',
    iconData: PhosphorIconsRegular.divide,
  ),
  MemoToolbarCustomIconOption(
    key: 'dna',
    label: 'Dna',
    iconData: PhosphorIconsRegular.dna,
  ),
  MemoToolbarCustomIconOption(
    key: 'dog',
    label: 'Dog',
    iconData: PhosphorIconsRegular.dog,
  ),
  MemoToolbarCustomIconOption(
    key: 'door',
    label: 'Door',
    iconData: PhosphorIconsRegular.door,
  ),
  MemoToolbarCustomIconOption(
    key: 'doorOpen',
    label: 'Door Open',
    iconData: PhosphorIconsRegular.doorOpen,
  ),
  MemoToolbarCustomIconOption(
    key: 'dot',
    label: 'Dot',
    iconData: PhosphorIconsRegular.dot,
  ),
  MemoToolbarCustomIconOption(
    key: 'dotOutline',
    label: 'Dot Outline',
    iconData: PhosphorIconsRegular.dotOutline,
  ),
  MemoToolbarCustomIconOption(
    key: 'dotsNine',
    label: 'Dots Nine',
    iconData: PhosphorIconsRegular.dotsNine,
  ),
  MemoToolbarCustomIconOption(
    key: 'dotsSix',
    label: 'Dots Six',
    iconData: PhosphorIconsRegular.dotsSix,
  ),
  MemoToolbarCustomIconOption(
    key: 'dotsSixVertical',
    label: 'Dots Six Vertical',
    iconData: PhosphorIconsRegular.dotsSixVertical,
  ),
  MemoToolbarCustomIconOption(
    key: 'dotsThree',
    label: 'Dots Three',
    iconData: PhosphorIconsRegular.dotsThree,
  ),
  MemoToolbarCustomIconOption(
    key: 'dotsThreeCircle',
    label: 'Dots Three Circle',
    iconData: PhosphorIconsRegular.dotsThreeCircle,
  ),
  MemoToolbarCustomIconOption(
    key: 'dotsThreeOutline',
    label: 'Dots Three Outline',
    iconData: PhosphorIconsRegular.dotsThreeOutline,
  ),
  MemoToolbarCustomIconOption(
    key: 'dotsThreeVertical',
    label: 'Dots Three Vertical',
    iconData: PhosphorIconsRegular.dotsThreeVertical,
  ),
  MemoToolbarCustomIconOption(
    key: 'download',
    label: 'Download',
    iconData: PhosphorIconsRegular.download,
  ),
  MemoToolbarCustomIconOption(
    key: 'downloadSimple',
    label: 'Download Simple',
    iconData: PhosphorIconsRegular.downloadSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'dress',
    label: 'Dress',
    iconData: PhosphorIconsRegular.dress,
  ),
  MemoToolbarCustomIconOption(
    key: 'dresser',
    label: 'Dresser',
    iconData: PhosphorIconsRegular.dresser,
  ),
  MemoToolbarCustomIconOption(
    key: 'dribbbleLogo',
    label: 'Dribbble Logo',
    iconData: PhosphorIconsRegular.dribbbleLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'drone',
    label: 'Drone',
    iconData: PhosphorIconsRegular.drone,
  ),
  MemoToolbarCustomIconOption(
    key: 'drop',
    label: 'Drop',
    iconData: PhosphorIconsRegular.drop,
  ),
  MemoToolbarCustomIconOption(
    key: 'dropHalf',
    label: 'Drop Half',
    iconData: PhosphorIconsRegular.dropHalf,
  ),
  MemoToolbarCustomIconOption(
    key: 'dropHalfBottom',
    label: 'Drop Half Bottom',
    iconData: PhosphorIconsRegular.dropHalfBottom,
  ),
  MemoToolbarCustomIconOption(
    key: 'dropSimple',
    label: 'Drop Simple',
    iconData: PhosphorIconsRegular.dropSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'dropSlash',
    label: 'Drop Slash',
    iconData: PhosphorIconsRegular.dropSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'dropboxLogo',
    label: 'Dropbox Logo',
    iconData: PhosphorIconsRegular.dropboxLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'ear',
    label: 'Ear',
    iconData: PhosphorIconsRegular.ear,
  ),
  MemoToolbarCustomIconOption(
    key: 'earSlash',
    label: 'Ear Slash',
    iconData: PhosphorIconsRegular.earSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'egg',
    label: 'Egg',
    iconData: PhosphorIconsRegular.egg,
  ),
  MemoToolbarCustomIconOption(
    key: 'eggCrack',
    label: 'Egg Crack',
    iconData: PhosphorIconsRegular.eggCrack,
  ),
  MemoToolbarCustomIconOption(
    key: 'eject',
    label: 'Eject',
    iconData: PhosphorIconsRegular.eject,
  ),
  MemoToolbarCustomIconOption(
    key: 'ejectSimple',
    label: 'Eject Simple',
    iconData: PhosphorIconsRegular.ejectSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'elevator',
    label: 'Elevator',
    iconData: PhosphorIconsRegular.elevator,
  ),
  MemoToolbarCustomIconOption(
    key: 'empty',
    label: 'Empty',
    iconData: PhosphorIconsRegular.empty,
  ),
  MemoToolbarCustomIconOption(
    key: 'engine',
    label: 'Engine',
    iconData: PhosphorIconsRegular.engine,
  ),
  MemoToolbarCustomIconOption(
    key: 'envelope',
    label: 'Envelope',
    iconData: PhosphorIconsRegular.envelope,
  ),
  MemoToolbarCustomIconOption(
    key: 'envelopeOpen',
    label: 'Envelope Open',
    iconData: PhosphorIconsRegular.envelopeOpen,
  ),
  MemoToolbarCustomIconOption(
    key: 'envelopeSimple',
    label: 'Envelope Simple',
    iconData: PhosphorIconsRegular.envelopeSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'envelopeSimpleOpen',
    label: 'Envelope Simple Open',
    iconData: PhosphorIconsRegular.envelopeSimpleOpen,
  ),
  MemoToolbarCustomIconOption(
    key: 'equalizer',
    label: 'Equalizer',
    iconData: PhosphorIconsRegular.equalizer,
  ),
  MemoToolbarCustomIconOption(
    key: 'equals',
    label: 'Equals',
    iconData: PhosphorIconsRegular.equals,
  ),
  MemoToolbarCustomIconOption(
    key: 'eraser',
    label: 'Eraser',
    iconData: PhosphorIconsRegular.eraser,
  ),
  MemoToolbarCustomIconOption(
    key: 'escalatorDown',
    label: 'Escalator Down',
    iconData: PhosphorIconsRegular.escalatorDown,
  ),
  MemoToolbarCustomIconOption(
    key: 'escalatorUp',
    label: 'Escalator Up',
    iconData: PhosphorIconsRegular.escalatorUp,
  ),
  MemoToolbarCustomIconOption(
    key: 'exam',
    label: 'Exam',
    iconData: PhosphorIconsRegular.exam,
  ),
  MemoToolbarCustomIconOption(
    key: 'exclamationMark',
    label: 'Exclamation Mark',
    iconData: PhosphorIconsRegular.exclamationMark,
  ),
  MemoToolbarCustomIconOption(
    key: 'exclude',
    label: 'Exclude',
    iconData: PhosphorIconsRegular.exclude,
  ),
  MemoToolbarCustomIconOption(
    key: 'excludeSquare',
    label: 'Exclude Square',
    iconData: PhosphorIconsRegular.excludeSquare,
  ),
  MemoToolbarCustomIconOption(
    key: 'export',
    label: 'Export',
    iconData: PhosphorIconsRegular.export,
  ),
  MemoToolbarCustomIconOption(
    key: 'eye',
    label: 'Eye',
    iconData: PhosphorIconsRegular.eye,
  ),
  MemoToolbarCustomIconOption(
    key: 'eyeClosed',
    label: 'Eye Closed',
    iconData: PhosphorIconsRegular.eyeClosed,
  ),
  MemoToolbarCustomIconOption(
    key: 'eyeSlash',
    label: 'Eye Slash',
    iconData: PhosphorIconsRegular.eyeSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'eyedropper',
    label: 'Eyedropper',
    iconData: PhosphorIconsRegular.eyedropper,
  ),
  MemoToolbarCustomIconOption(
    key: 'eyedropperSample',
    label: 'Eyedropper Sample',
    iconData: PhosphorIconsRegular.eyedropperSample,
  ),
  MemoToolbarCustomIconOption(
    key: 'eyeglasses',
    label: 'Eyeglasses',
    iconData: PhosphorIconsRegular.eyeglasses,
  ),
  MemoToolbarCustomIconOption(
    key: 'eyes',
    label: 'Eyes',
    iconData: PhosphorIconsRegular.eyes,
  ),
  MemoToolbarCustomIconOption(
    key: 'faceMask',
    label: 'Face Mask',
    iconData: PhosphorIconsRegular.faceMask,
  ),
  MemoToolbarCustomIconOption(
    key: 'facebookLogo',
    label: 'Facebook Logo',
    iconData: PhosphorIconsRegular.facebookLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'factory',
    label: 'Factory',
    iconData: PhosphorIconsRegular.factory,
  ),
  MemoToolbarCustomIconOption(
    key: 'faders',
    label: 'Faders',
    iconData: PhosphorIconsRegular.faders,
  ),
  MemoToolbarCustomIconOption(
    key: 'fadersHorizontal',
    label: 'Faders Horizontal',
    iconData: PhosphorIconsRegular.fadersHorizontal,
  ),
  MemoToolbarCustomIconOption(
    key: 'falloutShelter',
    label: 'Fallout Shelter',
    iconData: PhosphorIconsRegular.falloutShelter,
  ),
  MemoToolbarCustomIconOption(
    key: 'fan',
    label: 'Fan',
    iconData: PhosphorIconsRegular.fan,
  ),
  MemoToolbarCustomIconOption(
    key: 'farm',
    label: 'Farm',
    iconData: PhosphorIconsRegular.farm,
  ),
  MemoToolbarCustomIconOption(
    key: 'fastForward',
    label: 'Fast Forward',
    iconData: PhosphorIconsRegular.fastForward,
  ),
  MemoToolbarCustomIconOption(
    key: 'fastForwardCircle',
    label: 'Fast Forward Circle',
    iconData: PhosphorIconsRegular.fastForwardCircle,
  ),
  MemoToolbarCustomIconOption(
    key: 'feather',
    label: 'Feather',
    iconData: PhosphorIconsRegular.feather,
  ),
  MemoToolbarCustomIconOption(
    key: 'fediverseLogo',
    label: 'Fediverse Logo',
    iconData: PhosphorIconsRegular.fediverseLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'figmaLogo',
    label: 'Figma Logo',
    iconData: PhosphorIconsRegular.figmaLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'file',
    label: 'File',
    iconData: PhosphorIconsRegular.file,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileArchive',
    label: 'File Archive',
    iconData: PhosphorIconsRegular.fileArchive,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileArrowDown',
    label: 'File Arrow Down',
    iconData: PhosphorIconsRegular.fileArrowDown,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileArrowUp',
    label: 'File Arrow Up',
    iconData: PhosphorIconsRegular.fileArrowUp,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileAudio',
    label: 'File Audio',
    iconData: PhosphorIconsRegular.fileAudio,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileC',
    label: 'File C',
    iconData: PhosphorIconsRegular.fileC,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileCSharp',
    label: 'File C Sharp',
    iconData: PhosphorIconsRegular.fileCSharp,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileCloud',
    label: 'File Cloud',
    iconData: PhosphorIconsRegular.fileCloud,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileCode',
    label: 'File Code',
    iconData: PhosphorIconsRegular.fileCode,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileCpp',
    label: 'File Cpp',
    iconData: PhosphorIconsRegular.fileCpp,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileCss',
    label: 'File Css',
    iconData: PhosphorIconsRegular.fileCss,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileCsv',
    label: 'File Csv',
    iconData: PhosphorIconsRegular.fileCsv,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileDashed',
    label: 'File Dashed',
    iconData: PhosphorIconsRegular.fileDashed,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileDoc',
    label: 'File Doc',
    iconData: PhosphorIconsRegular.fileDoc,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileHtml',
    label: 'File Html',
    iconData: PhosphorIconsRegular.fileHtml,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileImage',
    label: 'File Image',
    iconData: PhosphorIconsRegular.fileImage,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileIni',
    label: 'File Ini',
    iconData: PhosphorIconsRegular.fileIni,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileJpg',
    label: 'File Jpg',
    iconData: PhosphorIconsRegular.fileJpg,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileJs',
    label: 'File Js',
    iconData: PhosphorIconsRegular.fileJs,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileJsx',
    label: 'File Jsx',
    iconData: PhosphorIconsRegular.fileJsx,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileLock',
    label: 'File Lock',
    iconData: PhosphorIconsRegular.fileLock,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileMagnifyingGlass',
    label: 'File Magnifying Glass',
    iconData: PhosphorIconsRegular.fileMagnifyingGlass,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileMd',
    label: 'File Md',
    iconData: PhosphorIconsRegular.fileMd,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileMinus',
    label: 'File Minus',
    iconData: PhosphorIconsRegular.fileMinus,
  ),
  MemoToolbarCustomIconOption(
    key: 'filePdf',
    label: 'File Pdf',
    iconData: PhosphorIconsRegular.filePdf,
  ),
  MemoToolbarCustomIconOption(
    key: 'filePlus',
    label: 'File Plus',
    iconData: PhosphorIconsRegular.filePlus,
  ),
  MemoToolbarCustomIconOption(
    key: 'filePng',
    label: 'File Png',
    iconData: PhosphorIconsRegular.filePng,
  ),
  MemoToolbarCustomIconOption(
    key: 'filePpt',
    label: 'File Ppt',
    iconData: PhosphorIconsRegular.filePpt,
  ),
  MemoToolbarCustomIconOption(
    key: 'filePy',
    label: 'File Py',
    iconData: PhosphorIconsRegular.filePy,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileRs',
    label: 'File Rs',
    iconData: PhosphorIconsRegular.fileRs,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileSql',
    label: 'File Sql',
    iconData: PhosphorIconsRegular.fileSql,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileSvg',
    label: 'File Svg',
    iconData: PhosphorIconsRegular.fileSvg,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileText',
    label: 'File Text',
    iconData: PhosphorIconsRegular.fileText,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileTs',
    label: 'File Ts',
    iconData: PhosphorIconsRegular.fileTs,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileTsx',
    label: 'File Tsx',
    iconData: PhosphorIconsRegular.fileTsx,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileTxt',
    label: 'File Txt',
    iconData: PhosphorIconsRegular.fileTxt,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileVideo',
    label: 'File Video',
    iconData: PhosphorIconsRegular.fileVideo,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileVue',
    label: 'File Vue',
    iconData: PhosphorIconsRegular.fileVue,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileX',
    label: 'File X',
    iconData: PhosphorIconsRegular.fileX,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileXls',
    label: 'File Xls',
    iconData: PhosphorIconsRegular.fileXls,
  ),
  MemoToolbarCustomIconOption(
    key: 'fileZip',
    label: 'File Zip',
    iconData: PhosphorIconsRegular.fileZip,
  ),
  MemoToolbarCustomIconOption(
    key: 'files',
    label: 'Files',
    iconData: PhosphorIconsRegular.files,
  ),
  MemoToolbarCustomIconOption(
    key: 'filmReel',
    label: 'Film Reel',
    iconData: PhosphorIconsRegular.filmReel,
  ),
  MemoToolbarCustomIconOption(
    key: 'filmScript',
    label: 'Film Script',
    iconData: PhosphorIconsRegular.filmScript,
  ),
  MemoToolbarCustomIconOption(
    key: 'filmSlate',
    label: 'Film Slate',
    iconData: PhosphorIconsRegular.filmSlate,
  ),
  MemoToolbarCustomIconOption(
    key: 'filmStrip',
    label: 'Film Strip',
    iconData: PhosphorIconsRegular.filmStrip,
  ),
  MemoToolbarCustomIconOption(
    key: 'fingerprint',
    label: 'Fingerprint',
    iconData: PhosphorIconsRegular.fingerprint,
  ),
  MemoToolbarCustomIconOption(
    key: 'fingerprintSimple',
    label: 'Fingerprint Simple',
    iconData: PhosphorIconsRegular.fingerprintSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'finnTheHuman',
    label: 'Finn The Human',
    iconData: PhosphorIconsRegular.finnTheHuman,
  ),
  MemoToolbarCustomIconOption(
    key: 'fire',
    label: 'Fire',
    iconData: PhosphorIconsRegular.fire,
  ),
  MemoToolbarCustomIconOption(
    key: 'fireExtinguisher',
    label: 'Fire Extinguisher',
    iconData: PhosphorIconsRegular.fireExtinguisher,
  ),
  MemoToolbarCustomIconOption(
    key: 'fireSimple',
    label: 'Fire Simple',
    iconData: PhosphorIconsRegular.fireSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'fireTruck',
    label: 'Fire Truck',
    iconData: PhosphorIconsRegular.fireTruck,
  ),
  MemoToolbarCustomIconOption(
    key: 'firstAid',
    label: 'First Aid',
    iconData: PhosphorIconsRegular.firstAid,
  ),
  MemoToolbarCustomIconOption(
    key: 'firstAidKit',
    label: 'First Aid Kit',
    iconData: PhosphorIconsRegular.firstAidKit,
  ),
  MemoToolbarCustomIconOption(
    key: 'fish',
    label: 'Fish',
    iconData: PhosphorIconsRegular.fish,
  ),
  MemoToolbarCustomIconOption(
    key: 'fishSimple',
    label: 'Fish Simple',
    iconData: PhosphorIconsRegular.fishSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'flag',
    label: 'Flag',
    iconData: PhosphorIconsRegular.flag,
  ),
  MemoToolbarCustomIconOption(
    key: 'flagBanner',
    label: 'Flag Banner',
    iconData: PhosphorIconsRegular.flagBanner,
  ),
  MemoToolbarCustomIconOption(
    key: 'flagBannerFold',
    label: 'Flag Banner Fold',
    iconData: PhosphorIconsRegular.flagBannerFold,
  ),
  MemoToolbarCustomIconOption(
    key: 'flagCheckered',
    label: 'Flag Checkered',
    iconData: PhosphorIconsRegular.flagCheckered,
  ),
  MemoToolbarCustomIconOption(
    key: 'flagPennant',
    label: 'Flag Pennant',
    iconData: PhosphorIconsRegular.flagPennant,
  ),
  MemoToolbarCustomIconOption(
    key: 'flame',
    label: 'Flame',
    iconData: PhosphorIconsRegular.flame,
  ),
  MemoToolbarCustomIconOption(
    key: 'flashlight',
    label: 'Flashlight',
    iconData: PhosphorIconsRegular.flashlight,
  ),
  MemoToolbarCustomIconOption(
    key: 'flask',
    label: 'Flask',
    iconData: PhosphorIconsRegular.flask,
  ),
  MemoToolbarCustomIconOption(
    key: 'flipHorizontal',
    label: 'Flip Horizontal',
    iconData: PhosphorIconsRegular.flipHorizontal,
  ),
  MemoToolbarCustomIconOption(
    key: 'flipVertical',
    label: 'Flip Vertical',
    iconData: PhosphorIconsRegular.flipVertical,
  ),
  MemoToolbarCustomIconOption(
    key: 'floppyDisk',
    label: 'Floppy Disk',
    iconData: PhosphorIconsRegular.floppyDisk,
  ),
  MemoToolbarCustomIconOption(
    key: 'floppyDiskBack',
    label: 'Floppy Disk Back',
    iconData: PhosphorIconsRegular.floppyDiskBack,
  ),
  MemoToolbarCustomIconOption(
    key: 'flowArrow',
    label: 'Flow Arrow',
    iconData: PhosphorIconsRegular.flowArrow,
  ),
  MemoToolbarCustomIconOption(
    key: 'flower',
    label: 'Flower',
    iconData: PhosphorIconsRegular.flower,
  ),
  MemoToolbarCustomIconOption(
    key: 'flowerLotus',
    label: 'Flower Lotus',
    iconData: PhosphorIconsRegular.flowerLotus,
  ),
  MemoToolbarCustomIconOption(
    key: 'flowerTulip',
    label: 'Flower Tulip',
    iconData: PhosphorIconsRegular.flowerTulip,
  ),
  MemoToolbarCustomIconOption(
    key: 'flyingSaucer',
    label: 'Flying Saucer',
    iconData: PhosphorIconsRegular.flyingSaucer,
  ),
  MemoToolbarCustomIconOption(
    key: 'folder',
    label: 'Folder',
    iconData: PhosphorIconsRegular.folder,
  ),
  MemoToolbarCustomIconOption(
    key: 'folderDashed',
    label: 'Folder Dashed',
    iconData: PhosphorIconsRegular.folderDashed,
  ),
  MemoToolbarCustomIconOption(
    key: 'folderLock',
    label: 'Folder Lock',
    iconData: PhosphorIconsRegular.folderLock,
  ),
  MemoToolbarCustomIconOption(
    key: 'folderMinus',
    label: 'Folder Minus',
    iconData: PhosphorIconsRegular.folderMinus,
  ),
  MemoToolbarCustomIconOption(
    key: 'folderOpen',
    label: 'Folder Open',
    iconData: PhosphorIconsRegular.folderOpen,
  ),
  MemoToolbarCustomIconOption(
    key: 'folderPlus',
    label: 'Folder Plus',
    iconData: PhosphorIconsRegular.folderPlus,
  ),
  MemoToolbarCustomIconOption(
    key: 'folderSimple',
    label: 'Folder Simple',
    iconData: PhosphorIconsRegular.folderSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'folderSimpleDashed',
    label: 'Folder Simple Dashed',
    iconData: PhosphorIconsRegular.folderSimpleDashed,
  ),
  MemoToolbarCustomIconOption(
    key: 'folderSimpleLock',
    label: 'Folder Simple Lock',
    iconData: PhosphorIconsRegular.folderSimpleLock,
  ),
  MemoToolbarCustomIconOption(
    key: 'folderSimpleMinus',
    label: 'Folder Simple Minus',
    iconData: PhosphorIconsRegular.folderSimpleMinus,
  ),
  MemoToolbarCustomIconOption(
    key: 'folderSimplePlus',
    label: 'Folder Simple Plus',
    iconData: PhosphorIconsRegular.folderSimplePlus,
  ),
  MemoToolbarCustomIconOption(
    key: 'folderSimpleStar',
    label: 'Folder Simple Star',
    iconData: PhosphorIconsRegular.folderSimpleStar,
  ),
  MemoToolbarCustomIconOption(
    key: 'folderSimpleUser',
    label: 'Folder Simple User',
    iconData: PhosphorIconsRegular.folderSimpleUser,
  ),
  MemoToolbarCustomIconOption(
    key: 'folderStar',
    label: 'Folder Star',
    iconData: PhosphorIconsRegular.folderStar,
  ),
  MemoToolbarCustomIconOption(
    key: 'folderUser',
    label: 'Folder User',
    iconData: PhosphorIconsRegular.folderUser,
  ),
  MemoToolbarCustomIconOption(
    key: 'folders',
    label: 'Folders',
    iconData: PhosphorIconsRegular.folders,
  ),
  MemoToolbarCustomIconOption(
    key: 'football',
    label: 'Football',
    iconData: PhosphorIconsRegular.football,
  ),
  MemoToolbarCustomIconOption(
    key: 'footballHelmet',
    label: 'Football Helmet',
    iconData: PhosphorIconsRegular.footballHelmet,
  ),
  MemoToolbarCustomIconOption(
    key: 'footprints',
    label: 'Footprints',
    iconData: PhosphorIconsRegular.footprints,
  ),
  MemoToolbarCustomIconOption(
    key: 'forkKnife',
    label: 'Fork Knife',
    iconData: PhosphorIconsRegular.forkKnife,
  ),
  MemoToolbarCustomIconOption(
    key: 'fourK',
    label: 'Four K',
    iconData: PhosphorIconsRegular.fourK,
  ),
  MemoToolbarCustomIconOption(
    key: 'frameCorners',
    label: 'Frame Corners',
    iconData: PhosphorIconsRegular.frameCorners,
  ),
  MemoToolbarCustomIconOption(
    key: 'framerLogo',
    label: 'Framer Logo',
    iconData: PhosphorIconsRegular.framerLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'function',
    label: 'Function',
    iconData: PhosphorIconsRegular.function,
  ),
  MemoToolbarCustomIconOption(
    key: 'funnel',
    label: 'Funnel',
    iconData: PhosphorIconsRegular.funnel,
  ),
  MemoToolbarCustomIconOption(
    key: 'funnelSimple',
    label: 'Funnel Simple',
    iconData: PhosphorIconsRegular.funnelSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'funnelSimpleX',
    label: 'Funnel Simple X',
    iconData: PhosphorIconsRegular.funnelSimpleX,
  ),
  MemoToolbarCustomIconOption(
    key: 'funnelX',
    label: 'Funnel X',
    iconData: PhosphorIconsRegular.funnelX,
  ),
  MemoToolbarCustomIconOption(
    key: 'gameController',
    label: 'Game Controller',
    iconData: PhosphorIconsRegular.gameController,
  ),
  MemoToolbarCustomIconOption(
    key: 'garage',
    label: 'Garage',
    iconData: PhosphorIconsRegular.garage,
  ),
  MemoToolbarCustomIconOption(
    key: 'gasCan',
    label: 'Gas Can',
    iconData: PhosphorIconsRegular.gasCan,
  ),
  MemoToolbarCustomIconOption(
    key: 'gasPump',
    label: 'Gas Pump',
    iconData: PhosphorIconsRegular.gasPump,
  ),
  MemoToolbarCustomIconOption(
    key: 'gauge',
    label: 'Gauge',
    iconData: PhosphorIconsRegular.gauge,
  ),
  MemoToolbarCustomIconOption(
    key: 'gavel',
    label: 'Gavel',
    iconData: PhosphorIconsRegular.gavel,
  ),
  MemoToolbarCustomIconOption(
    key: 'gear',
    label: 'Gear',
    iconData: PhosphorIconsRegular.gear,
  ),
  MemoToolbarCustomIconOption(
    key: 'gearFine',
    label: 'Gear Fine',
    iconData: PhosphorIconsRegular.gearFine,
  ),
  MemoToolbarCustomIconOption(
    key: 'gearSix',
    label: 'Gear Six',
    iconData: PhosphorIconsRegular.gearSix,
  ),
  MemoToolbarCustomIconOption(
    key: 'genderFemale',
    label: 'Gender Female',
    iconData: PhosphorIconsRegular.genderFemale,
  ),
  MemoToolbarCustomIconOption(
    key: 'genderIntersex',
    label: 'Gender Intersex',
    iconData: PhosphorIconsRegular.genderIntersex,
  ),
  MemoToolbarCustomIconOption(
    key: 'genderMale',
    label: 'Gender Male',
    iconData: PhosphorIconsRegular.genderMale,
  ),
  MemoToolbarCustomIconOption(
    key: 'genderNeuter',
    label: 'Gender Neuter',
    iconData: PhosphorIconsRegular.genderNeuter,
  ),
  MemoToolbarCustomIconOption(
    key: 'genderNonbinary',
    label: 'Gender Nonbinary',
    iconData: PhosphorIconsRegular.genderNonbinary,
  ),
  MemoToolbarCustomIconOption(
    key: 'genderTransgender',
    label: 'Gender Transgender',
    iconData: PhosphorIconsRegular.genderTransgender,
  ),
  MemoToolbarCustomIconOption(
    key: 'ghost',
    label: 'Ghost',
    iconData: PhosphorIconsRegular.ghost,
  ),
  MemoToolbarCustomIconOption(
    key: 'gif',
    label: 'Gif',
    iconData: PhosphorIconsRegular.gif,
  ),
  MemoToolbarCustomIconOption(
    key: 'gift',
    label: 'Gift',
    iconData: PhosphorIconsRegular.gift,
  ),
  MemoToolbarCustomIconOption(
    key: 'gitBranch',
    label: 'Git Branch',
    iconData: PhosphorIconsRegular.gitBranch,
  ),
  MemoToolbarCustomIconOption(
    key: 'gitCommit',
    label: 'Git Commit',
    iconData: PhosphorIconsRegular.gitCommit,
  ),
  MemoToolbarCustomIconOption(
    key: 'gitDiff',
    label: 'Git Diff',
    iconData: PhosphorIconsRegular.gitDiff,
  ),
  MemoToolbarCustomIconOption(
    key: 'gitFork',
    label: 'Git Fork',
    iconData: PhosphorIconsRegular.gitFork,
  ),
  MemoToolbarCustomIconOption(
    key: 'gitMerge',
    label: 'Git Merge',
    iconData: PhosphorIconsRegular.gitMerge,
  ),
  MemoToolbarCustomIconOption(
    key: 'gitPullRequest',
    label: 'Git Pull Request',
    iconData: PhosphorIconsRegular.gitPullRequest,
  ),
  MemoToolbarCustomIconOption(
    key: 'githubLogo',
    label: 'Github Logo',
    iconData: PhosphorIconsRegular.githubLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'gitlabLogo',
    label: 'Gitlab Logo',
    iconData: PhosphorIconsRegular.gitlabLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'gitlabLogoSimple',
    label: 'Gitlab Logo Simple',
    iconData: PhosphorIconsRegular.gitlabLogoSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'globe',
    label: 'Globe',
    iconData: PhosphorIconsRegular.globe,
  ),
  MemoToolbarCustomIconOption(
    key: 'globeHemisphereEast',
    label: 'Globe Hemisphere East',
    iconData: PhosphorIconsRegular.globeHemisphereEast,
  ),
  MemoToolbarCustomIconOption(
    key: 'globeHemisphereWest',
    label: 'Globe Hemisphere West',
    iconData: PhosphorIconsRegular.globeHemisphereWest,
  ),
  MemoToolbarCustomIconOption(
    key: 'globeSimple',
    label: 'Globe Simple',
    iconData: PhosphorIconsRegular.globeSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'globeSimpleX',
    label: 'Globe Simple X',
    iconData: PhosphorIconsRegular.globeSimpleX,
  ),
  MemoToolbarCustomIconOption(
    key: 'globeStand',
    label: 'Globe Stand',
    iconData: PhosphorIconsRegular.globeStand,
  ),
  MemoToolbarCustomIconOption(
    key: 'globeX',
    label: 'Globe X',
    iconData: PhosphorIconsRegular.globeX,
  ),
  MemoToolbarCustomIconOption(
    key: 'goggles',
    label: 'Goggles',
    iconData: PhosphorIconsRegular.goggles,
  ),
  MemoToolbarCustomIconOption(
    key: 'golf',
    label: 'Golf',
    iconData: PhosphorIconsRegular.golf,
  ),
  MemoToolbarCustomIconOption(
    key: 'goodreadsLogo',
    label: 'Goodreads Logo',
    iconData: PhosphorIconsRegular.goodreadsLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'googleCardboardLogo',
    label: 'Google Cardboard Logo',
    iconData: PhosphorIconsRegular.googleCardboardLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'googleChromeLogo',
    label: 'Google Chrome Logo',
    iconData: PhosphorIconsRegular.googleChromeLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'googleDriveLogo',
    label: 'Google Drive Logo',
    iconData: PhosphorIconsRegular.googleDriveLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'googleLogo',
    label: 'Google Logo',
    iconData: PhosphorIconsRegular.googleLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'googlePhotosLogo',
    label: 'Google Photos Logo',
    iconData: PhosphorIconsRegular.googlePhotosLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'googlePlayLogo',
    label: 'Google Play Logo',
    iconData: PhosphorIconsRegular.googlePlayLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'googlePodcastsLogo',
    label: 'Google Podcasts Logo',
    iconData: PhosphorIconsRegular.googlePodcastsLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'gps',
    label: 'Gps',
    iconData: PhosphorIconsRegular.gps,
  ),
  MemoToolbarCustomIconOption(
    key: 'gpsFix',
    label: 'Gps Fix',
    iconData: PhosphorIconsRegular.gpsFix,
  ),
  MemoToolbarCustomIconOption(
    key: 'gpsSlash',
    label: 'Gps Slash',
    iconData: PhosphorIconsRegular.gpsSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'gradient',
    label: 'Gradient',
    iconData: PhosphorIconsRegular.gradient,
  ),
  MemoToolbarCustomIconOption(
    key: 'graduationCap',
    label: 'Graduation Cap',
    iconData: PhosphorIconsRegular.graduationCap,
  ),
  MemoToolbarCustomIconOption(
    key: 'grains',
    label: 'Grains',
    iconData: PhosphorIconsRegular.grains,
  ),
  MemoToolbarCustomIconOption(
    key: 'grainsSlash',
    label: 'Grains Slash',
    iconData: PhosphorIconsRegular.grainsSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'graph',
    label: 'Graph',
    iconData: PhosphorIconsRegular.graph,
  ),
  MemoToolbarCustomIconOption(
    key: 'graphicsCard',
    label: 'Graphics Card',
    iconData: PhosphorIconsRegular.graphicsCard,
  ),
  MemoToolbarCustomIconOption(
    key: 'greaterThan',
    label: 'Greater Than',
    iconData: PhosphorIconsRegular.greaterThan,
  ),
  MemoToolbarCustomIconOption(
    key: 'greaterThanOrEqual',
    label: 'Greater Than Or Equal',
    iconData: PhosphorIconsRegular.greaterThanOrEqual,
  ),
  MemoToolbarCustomIconOption(
    key: 'gridFour',
    label: 'Grid Four',
    iconData: PhosphorIconsRegular.gridFour,
  ),
  MemoToolbarCustomIconOption(
    key: 'gridNine',
    label: 'Grid Nine',
    iconData: PhosphorIconsRegular.gridNine,
  ),
  MemoToolbarCustomIconOption(
    key: 'guitar',
    label: 'Guitar',
    iconData: PhosphorIconsRegular.guitar,
  ),
  MemoToolbarCustomIconOption(
    key: 'hairDryer',
    label: 'Hair Dryer',
    iconData: PhosphorIconsRegular.hairDryer,
  ),
  MemoToolbarCustomIconOption(
    key: 'hamburger',
    label: 'Hamburger',
    iconData: PhosphorIconsRegular.hamburger,
  ),
  MemoToolbarCustomIconOption(
    key: 'hammer',
    label: 'Hammer',
    iconData: PhosphorIconsRegular.hammer,
  ),
  MemoToolbarCustomIconOption(
    key: 'hand',
    label: 'Hand',
    iconData: PhosphorIconsRegular.hand,
  ),
  MemoToolbarCustomIconOption(
    key: 'handArrowDown',
    label: 'Hand Arrow Down',
    iconData: PhosphorIconsRegular.handArrowDown,
  ),
  MemoToolbarCustomIconOption(
    key: 'handArrowUp',
    label: 'Hand Arrow Up',
    iconData: PhosphorIconsRegular.handArrowUp,
  ),
  MemoToolbarCustomIconOption(
    key: 'handCoins',
    label: 'Hand Coins',
    iconData: PhosphorIconsRegular.handCoins,
  ),
  MemoToolbarCustomIconOption(
    key: 'handDeposit',
    label: 'Hand Deposit',
    iconData: PhosphorIconsRegular.handDeposit,
  ),
  MemoToolbarCustomIconOption(
    key: 'handEye',
    label: 'Hand Eye',
    iconData: PhosphorIconsRegular.handEye,
  ),
  MemoToolbarCustomIconOption(
    key: 'handFist',
    label: 'Hand Fist',
    iconData: PhosphorIconsRegular.handFist,
  ),
  MemoToolbarCustomIconOption(
    key: 'handGrabbing',
    label: 'Hand Grabbing',
    iconData: PhosphorIconsRegular.handGrabbing,
  ),
  MemoToolbarCustomIconOption(
    key: 'handHeart',
    label: 'Hand Heart',
    iconData: PhosphorIconsRegular.handHeart,
  ),
  MemoToolbarCustomIconOption(
    key: 'handPalm',
    label: 'Hand Palm',
    iconData: PhosphorIconsRegular.handPalm,
  ),
  MemoToolbarCustomIconOption(
    key: 'handPeace',
    label: 'Hand Peace',
    iconData: PhosphorIconsRegular.handPeace,
  ),
  MemoToolbarCustomIconOption(
    key: 'handPointing',
    label: 'Hand Pointing',
    iconData: PhosphorIconsRegular.handPointing,
  ),
  MemoToolbarCustomIconOption(
    key: 'handSoap',
    label: 'Hand Soap',
    iconData: PhosphorIconsRegular.handSoap,
  ),
  MemoToolbarCustomIconOption(
    key: 'handSwipeLeft',
    label: 'Hand Swipe Left',
    iconData: PhosphorIconsRegular.handSwipeLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'handSwipeRight',
    label: 'Hand Swipe Right',
    iconData: PhosphorIconsRegular.handSwipeRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'handTap',
    label: 'Hand Tap',
    iconData: PhosphorIconsRegular.handTap,
  ),
  MemoToolbarCustomIconOption(
    key: 'handWaving',
    label: 'Hand Waving',
    iconData: PhosphorIconsRegular.handWaving,
  ),
  MemoToolbarCustomIconOption(
    key: 'handWithdraw',
    label: 'Hand Withdraw',
    iconData: PhosphorIconsRegular.handWithdraw,
  ),
  MemoToolbarCustomIconOption(
    key: 'handbag',
    label: 'Handbag',
    iconData: PhosphorIconsRegular.handbag,
  ),
  MemoToolbarCustomIconOption(
    key: 'handbagSimple',
    label: 'Handbag Simple',
    iconData: PhosphorIconsRegular.handbagSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'handsClapping',
    label: 'Hands Clapping',
    iconData: PhosphorIconsRegular.handsClapping,
  ),
  MemoToolbarCustomIconOption(
    key: 'handsPraying',
    label: 'Hands Praying',
    iconData: PhosphorIconsRegular.handsPraying,
  ),
  MemoToolbarCustomIconOption(
    key: 'handshake',
    label: 'Handshake',
    iconData: PhosphorIconsRegular.handshake,
  ),
  MemoToolbarCustomIconOption(
    key: 'hardDrive',
    label: 'Hard Drive',
    iconData: PhosphorIconsRegular.hardDrive,
  ),
  MemoToolbarCustomIconOption(
    key: 'hardDrives',
    label: 'Hard Drives',
    iconData: PhosphorIconsRegular.hardDrives,
  ),
  MemoToolbarCustomIconOption(
    key: 'hardHat',
    label: 'Hard Hat',
    iconData: PhosphorIconsRegular.hardHat,
  ),
  MemoToolbarCustomIconOption(
    key: 'hash',
    label: 'Hash',
    iconData: PhosphorIconsRegular.hash,
  ),
  MemoToolbarCustomIconOption(
    key: 'hashStraight',
    label: 'Hash Straight',
    iconData: PhosphorIconsRegular.hashStraight,
  ),
  MemoToolbarCustomIconOption(
    key: 'headCircuit',
    label: 'Head Circuit',
    iconData: PhosphorIconsRegular.headCircuit,
  ),
  MemoToolbarCustomIconOption(
    key: 'headlights',
    label: 'Headlights',
    iconData: PhosphorIconsRegular.headlights,
  ),
  MemoToolbarCustomIconOption(
    key: 'headphones',
    label: 'Headphones',
    iconData: PhosphorIconsRegular.headphones,
  ),
  MemoToolbarCustomIconOption(
    key: 'headset',
    label: 'Headset',
    iconData: PhosphorIconsRegular.headset,
  ),
  MemoToolbarCustomIconOption(
    key: 'heart',
    label: 'Heart',
    iconData: PhosphorIconsRegular.heart,
  ),
  MemoToolbarCustomIconOption(
    key: 'heartBreak',
    label: 'Heart Break',
    iconData: PhosphorIconsRegular.heartBreak,
  ),
  MemoToolbarCustomIconOption(
    key: 'heartHalf',
    label: 'Heart Half',
    iconData: PhosphorIconsRegular.heartHalf,
  ),
  MemoToolbarCustomIconOption(
    key: 'heartStraight',
    label: 'Heart Straight',
    iconData: PhosphorIconsRegular.heartStraight,
  ),
  MemoToolbarCustomIconOption(
    key: 'heartStraightBreak',
    label: 'Heart Straight Break',
    iconData: PhosphorIconsRegular.heartStraightBreak,
  ),
  MemoToolbarCustomIconOption(
    key: 'heartbeat',
    label: 'Heartbeat',
    iconData: PhosphorIconsRegular.heartbeat,
  ),
  MemoToolbarCustomIconOption(
    key: 'hexagon',
    label: 'Hexagon',
    iconData: PhosphorIconsRegular.hexagon,
  ),
  MemoToolbarCustomIconOption(
    key: 'highDefinition',
    label: 'High Definition',
    iconData: PhosphorIconsRegular.highDefinition,
  ),
  MemoToolbarCustomIconOption(
    key: 'highHeel',
    label: 'High Heel',
    iconData: PhosphorIconsRegular.highHeel,
  ),
  MemoToolbarCustomIconOption(
    key: 'highlighter',
    label: 'Highlighter',
    iconData: PhosphorIconsRegular.highlighter,
  ),
  MemoToolbarCustomIconOption(
    key: 'highlighterCircle',
    label: 'Highlighter Circle',
    iconData: PhosphorIconsRegular.highlighterCircle,
  ),
  MemoToolbarCustomIconOption(
    key: 'hockey',
    label: 'Hockey',
    iconData: PhosphorIconsRegular.hockey,
  ),
  MemoToolbarCustomIconOption(
    key: 'hoodie',
    label: 'Hoodie',
    iconData: PhosphorIconsRegular.hoodie,
  ),
  MemoToolbarCustomIconOption(
    key: 'horse',
    label: 'Horse',
    iconData: PhosphorIconsRegular.horse,
  ),
  MemoToolbarCustomIconOption(
    key: 'hospital',
    label: 'Hospital',
    iconData: PhosphorIconsRegular.hospital,
  ),
  MemoToolbarCustomIconOption(
    key: 'hourglass',
    label: 'Hourglass',
    iconData: PhosphorIconsRegular.hourglass,
  ),
  MemoToolbarCustomIconOption(
    key: 'hourglassHigh',
    label: 'Hourglass High',
    iconData: PhosphorIconsRegular.hourglassHigh,
  ),
  MemoToolbarCustomIconOption(
    key: 'hourglassLow',
    label: 'Hourglass Low',
    iconData: PhosphorIconsRegular.hourglassLow,
  ),
  MemoToolbarCustomIconOption(
    key: 'hourglassMedium',
    label: 'Hourglass Medium',
    iconData: PhosphorIconsRegular.hourglassMedium,
  ),
  MemoToolbarCustomIconOption(
    key: 'hourglassSimple',
    label: 'Hourglass Simple',
    iconData: PhosphorIconsRegular.hourglassSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'hourglassSimpleHigh',
    label: 'Hourglass Simple High',
    iconData: PhosphorIconsRegular.hourglassSimpleHigh,
  ),
  MemoToolbarCustomIconOption(
    key: 'hourglassSimpleLow',
    label: 'Hourglass Simple Low',
    iconData: PhosphorIconsRegular.hourglassSimpleLow,
  ),
  MemoToolbarCustomIconOption(
    key: 'hourglassSimpleMedium',
    label: 'Hourglass Simple Medium',
    iconData: PhosphorIconsRegular.hourglassSimpleMedium,
  ),
  MemoToolbarCustomIconOption(
    key: 'house',
    label: 'House',
    iconData: PhosphorIconsRegular.house,
  ),
  MemoToolbarCustomIconOption(
    key: 'houseLine',
    label: 'House Line',
    iconData: PhosphorIconsRegular.houseLine,
  ),
  MemoToolbarCustomIconOption(
    key: 'houseSimple',
    label: 'House Simple',
    iconData: PhosphorIconsRegular.houseSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'hurricane',
    label: 'Hurricane',
    iconData: PhosphorIconsRegular.hurricane,
  ),
  MemoToolbarCustomIconOption(
    key: 'iceCream',
    label: 'Ice Cream',
    iconData: PhosphorIconsRegular.iceCream,
  ),
  MemoToolbarCustomIconOption(
    key: 'identificationBadge',
    label: 'Identification Badge',
    iconData: PhosphorIconsRegular.identificationBadge,
  ),
  MemoToolbarCustomIconOption(
    key: 'identificationCard',
    label: 'Identification Card',
    iconData: PhosphorIconsRegular.identificationCard,
  ),
  MemoToolbarCustomIconOption(
    key: 'image',
    label: 'Image',
    iconData: PhosphorIconsRegular.image,
  ),
  MemoToolbarCustomIconOption(
    key: 'imageBroken',
    label: 'Image Broken',
    iconData: PhosphorIconsRegular.imageBroken,
  ),
  MemoToolbarCustomIconOption(
    key: 'imageSquare',
    label: 'Image Square',
    iconData: PhosphorIconsRegular.imageSquare,
  ),
  MemoToolbarCustomIconOption(
    key: 'images',
    label: 'Images',
    iconData: PhosphorIconsRegular.images,
  ),
  MemoToolbarCustomIconOption(
    key: 'imagesSquare',
    label: 'Images Square',
    iconData: PhosphorIconsRegular.imagesSquare,
  ),
  MemoToolbarCustomIconOption(
    key: 'infinity',
    label: 'Infinity',
    iconData: PhosphorIconsRegular.infinity,
  ),
  MemoToolbarCustomIconOption(
    key: 'info',
    label: 'Info',
    iconData: PhosphorIconsRegular.info,
  ),
  MemoToolbarCustomIconOption(
    key: 'instagramLogo',
    label: 'Instagram Logo',
    iconData: PhosphorIconsRegular.instagramLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'intersect',
    label: 'Intersect',
    iconData: PhosphorIconsRegular.intersect,
  ),
  MemoToolbarCustomIconOption(
    key: 'intersectSquare',
    label: 'Intersect Square',
    iconData: PhosphorIconsRegular.intersectSquare,
  ),
  MemoToolbarCustomIconOption(
    key: 'intersectThree',
    label: 'Intersect Three',
    iconData: PhosphorIconsRegular.intersectThree,
  ),
  MemoToolbarCustomIconOption(
    key: 'intersection',
    label: 'Intersection',
    iconData: PhosphorIconsRegular.intersection,
  ),
  MemoToolbarCustomIconOption(
    key: 'invoice',
    label: 'Invoice',
    iconData: PhosphorIconsRegular.invoice,
  ),
  MemoToolbarCustomIconOption(
    key: 'island',
    label: 'Island',
    iconData: PhosphorIconsRegular.island,
  ),
  MemoToolbarCustomIconOption(
    key: 'jar',
    label: 'Jar',
    iconData: PhosphorIconsRegular.jar,
  ),
  MemoToolbarCustomIconOption(
    key: 'jarLabel',
    label: 'Jar Label',
    iconData: PhosphorIconsRegular.jarLabel,
  ),
  MemoToolbarCustomIconOption(
    key: 'jeep',
    label: 'Jeep',
    iconData: PhosphorIconsRegular.jeep,
  ),
  MemoToolbarCustomIconOption(
    key: 'joystick',
    label: 'Joystick',
    iconData: PhosphorIconsRegular.joystick,
  ),
  MemoToolbarCustomIconOption(
    key: 'kanban',
    label: 'Kanban',
    iconData: PhosphorIconsRegular.kanban,
  ),
  MemoToolbarCustomIconOption(
    key: 'key',
    label: 'Key',
    iconData: PhosphorIconsRegular.key,
  ),
  MemoToolbarCustomIconOption(
    key: 'keyReturn',
    label: 'Key Return',
    iconData: PhosphorIconsRegular.keyReturn,
  ),
  MemoToolbarCustomIconOption(
    key: 'keyboard',
    label: 'Keyboard',
    iconData: PhosphorIconsRegular.keyboard,
  ),
  MemoToolbarCustomIconOption(
    key: 'keyhole',
    label: 'Keyhole',
    iconData: PhosphorIconsRegular.keyhole,
  ),
  MemoToolbarCustomIconOption(
    key: 'knife',
    label: 'Knife',
    iconData: PhosphorIconsRegular.knife,
  ),
  MemoToolbarCustomIconOption(
    key: 'ladder',
    label: 'Ladder',
    iconData: PhosphorIconsRegular.ladder,
  ),
  MemoToolbarCustomIconOption(
    key: 'ladderSimple',
    label: 'Ladder Simple',
    iconData: PhosphorIconsRegular.ladderSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'lamp',
    label: 'Lamp',
    iconData: PhosphorIconsRegular.lamp,
  ),
  MemoToolbarCustomIconOption(
    key: 'lampPendant',
    label: 'Lamp Pendant',
    iconData: PhosphorIconsRegular.lampPendant,
  ),
  MemoToolbarCustomIconOption(
    key: 'laptop',
    label: 'Laptop',
    iconData: PhosphorIconsRegular.laptop,
  ),
  MemoToolbarCustomIconOption(
    key: 'lasso',
    label: 'Lasso',
    iconData: PhosphorIconsRegular.lasso,
  ),
  MemoToolbarCustomIconOption(
    key: 'lastfmLogo',
    label: 'Lastfm Logo',
    iconData: PhosphorIconsRegular.lastfmLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'layout',
    label: 'Layout',
    iconData: PhosphorIconsRegular.layout,
  ),
  MemoToolbarCustomIconOption(
    key: 'leaf',
    label: 'Leaf',
    iconData: PhosphorIconsRegular.leaf,
  ),
  MemoToolbarCustomIconOption(
    key: 'lectern',
    label: 'Lectern',
    iconData: PhosphorIconsRegular.lectern,
  ),
  MemoToolbarCustomIconOption(
    key: 'lego',
    label: 'Lego',
    iconData: PhosphorIconsRegular.lego,
  ),
  MemoToolbarCustomIconOption(
    key: 'legoSmiley',
    label: 'Lego Smiley',
    iconData: PhosphorIconsRegular.legoSmiley,
  ),
  MemoToolbarCustomIconOption(
    key: 'lessThan',
    label: 'Less Than',
    iconData: PhosphorIconsRegular.lessThan,
  ),
  MemoToolbarCustomIconOption(
    key: 'lessThanOrEqual',
    label: 'Less Than Or Equal',
    iconData: PhosphorIconsRegular.lessThanOrEqual,
  ),
  MemoToolbarCustomIconOption(
    key: 'letterCircleH',
    label: 'Letter Circle H',
    iconData: PhosphorIconsRegular.letterCircleH,
  ),
  MemoToolbarCustomIconOption(
    key: 'letterCircleP',
    label: 'Letter Circle P',
    iconData: PhosphorIconsRegular.letterCircleP,
  ),
  MemoToolbarCustomIconOption(
    key: 'letterCircleV',
    label: 'Letter Circle V',
    iconData: PhosphorIconsRegular.letterCircleV,
  ),
  MemoToolbarCustomIconOption(
    key: 'lifebuoy',
    label: 'Lifebuoy',
    iconData: PhosphorIconsRegular.lifebuoy,
  ),
  MemoToolbarCustomIconOption(
    key: 'lightbulb',
    label: 'Lightbulb',
    iconData: PhosphorIconsRegular.lightbulb,
  ),
  MemoToolbarCustomIconOption(
    key: 'lightbulbFilament',
    label: 'Lightbulb Filament',
    iconData: PhosphorIconsRegular.lightbulbFilament,
  ),
  MemoToolbarCustomIconOption(
    key: 'lighthouse',
    label: 'Lighthouse',
    iconData: PhosphorIconsRegular.lighthouse,
  ),
  MemoToolbarCustomIconOption(
    key: 'lightning',
    label: 'Lightning',
    iconData: PhosphorIconsRegular.lightning,
  ),
  MemoToolbarCustomIconOption(
    key: 'lightningA',
    label: 'Lightning A',
    iconData: PhosphorIconsRegular.lightningA,
  ),
  MemoToolbarCustomIconOption(
    key: 'lightningSlash',
    label: 'Lightning Slash',
    iconData: PhosphorIconsRegular.lightningSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'lineSegment',
    label: 'Line Segment',
    iconData: PhosphorIconsRegular.lineSegment,
  ),
  MemoToolbarCustomIconOption(
    key: 'lineSegments',
    label: 'Line Segments',
    iconData: PhosphorIconsRegular.lineSegments,
  ),
  MemoToolbarCustomIconOption(
    key: 'lineVertical',
    label: 'Line Vertical',
    iconData: PhosphorIconsRegular.lineVertical,
  ),
  MemoToolbarCustomIconOption(
    key: 'link',
    label: 'Link',
    iconData: PhosphorIconsRegular.link,
  ),
  MemoToolbarCustomIconOption(
    key: 'linkBreak',
    label: 'Link Break',
    iconData: PhosphorIconsRegular.linkBreak,
  ),
  MemoToolbarCustomIconOption(
    key: 'linkSimple',
    label: 'Link Simple',
    iconData: PhosphorIconsRegular.linkSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'linkSimpleBreak',
    label: 'Link Simple Break',
    iconData: PhosphorIconsRegular.linkSimpleBreak,
  ),
  MemoToolbarCustomIconOption(
    key: 'linkSimpleHorizontal',
    label: 'Link Simple Horizontal',
    iconData: PhosphorIconsRegular.linkSimpleHorizontal,
  ),
  MemoToolbarCustomIconOption(
    key: 'linkedinLogo',
    label: 'Linkedin Logo',
    iconData: PhosphorIconsRegular.linkedinLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'linktreeLogo',
    label: 'Linktree Logo',
    iconData: PhosphorIconsRegular.linktreeLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'linuxLogo',
    label: 'Linux Logo',
    iconData: PhosphorIconsRegular.linuxLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'list',
    label: 'List',
    iconData: PhosphorIconsRegular.list,
  ),
  MemoToolbarCustomIconOption(
    key: 'listBullets',
    label: 'List Bullets',
    iconData: PhosphorIconsRegular.listBullets,
  ),
  MemoToolbarCustomIconOption(
    key: 'listChecks',
    label: 'List Checks',
    iconData: PhosphorIconsRegular.listChecks,
  ),
  MemoToolbarCustomIconOption(
    key: 'listDashes',
    label: 'List Dashes',
    iconData: PhosphorIconsRegular.listDashes,
  ),
  MemoToolbarCustomIconOption(
    key: 'listHeart',
    label: 'List Heart',
    iconData: PhosphorIconsRegular.listHeart,
  ),
  MemoToolbarCustomIconOption(
    key: 'listMagnifyingGlass',
    label: 'List Magnifying Glass',
    iconData: PhosphorIconsRegular.listMagnifyingGlass,
  ),
  MemoToolbarCustomIconOption(
    key: 'listNumbers',
    label: 'List Numbers',
    iconData: PhosphorIconsRegular.listNumbers,
  ),
  MemoToolbarCustomIconOption(
    key: 'listPlus',
    label: 'List Plus',
    iconData: PhosphorIconsRegular.listPlus,
  ),
  MemoToolbarCustomIconOption(
    key: 'listStar',
    label: 'List Star',
    iconData: PhosphorIconsRegular.listStar,
  ),
  MemoToolbarCustomIconOption(
    key: 'lock',
    label: 'Lock',
    iconData: PhosphorIconsRegular.lock,
  ),
  MemoToolbarCustomIconOption(
    key: 'lockKey',
    label: 'Lock Key',
    iconData: PhosphorIconsRegular.lockKey,
  ),
  MemoToolbarCustomIconOption(
    key: 'lockKeyOpen',
    label: 'Lock Key Open',
    iconData: PhosphorIconsRegular.lockKeyOpen,
  ),
  MemoToolbarCustomIconOption(
    key: 'lockLaminated',
    label: 'Lock Laminated',
    iconData: PhosphorIconsRegular.lockLaminated,
  ),
  MemoToolbarCustomIconOption(
    key: 'lockLaminatedOpen',
    label: 'Lock Laminated Open',
    iconData: PhosphorIconsRegular.lockLaminatedOpen,
  ),
  MemoToolbarCustomIconOption(
    key: 'lockOpen',
    label: 'Lock Open',
    iconData: PhosphorIconsRegular.lockOpen,
  ),
  MemoToolbarCustomIconOption(
    key: 'lockSimple',
    label: 'Lock Simple',
    iconData: PhosphorIconsRegular.lockSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'lockSimpleOpen',
    label: 'Lock Simple Open',
    iconData: PhosphorIconsRegular.lockSimpleOpen,
  ),
  MemoToolbarCustomIconOption(
    key: 'lockers',
    label: 'Lockers',
    iconData: PhosphorIconsRegular.lockers,
  ),
  MemoToolbarCustomIconOption(
    key: 'log',
    label: 'Log',
    iconData: PhosphorIconsRegular.log,
  ),
  MemoToolbarCustomIconOption(
    key: 'magicWand',
    label: 'Magic Wand',
    iconData: PhosphorIconsRegular.magicWand,
  ),
  MemoToolbarCustomIconOption(
    key: 'magnet',
    label: 'Magnet',
    iconData: PhosphorIconsRegular.magnet,
  ),
  MemoToolbarCustomIconOption(
    key: 'magnetStraight',
    label: 'Magnet Straight',
    iconData: PhosphorIconsRegular.magnetStraight,
  ),
  MemoToolbarCustomIconOption(
    key: 'magnifyingGlass',
    label: 'Magnifying Glass',
    iconData: PhosphorIconsRegular.magnifyingGlass,
  ),
  MemoToolbarCustomIconOption(
    key: 'magnifyingGlassMinus',
    label: 'Magnifying Glass Minus',
    iconData: PhosphorIconsRegular.magnifyingGlassMinus,
  ),
  MemoToolbarCustomIconOption(
    key: 'magnifyingGlassPlus',
    label: 'Magnifying Glass Plus',
    iconData: PhosphorIconsRegular.magnifyingGlassPlus,
  ),
  MemoToolbarCustomIconOption(
    key: 'mailbox',
    label: 'Mailbox',
    iconData: PhosphorIconsRegular.mailbox,
  ),
  MemoToolbarCustomIconOption(
    key: 'mapPin',
    label: 'Map Pin',
    iconData: PhosphorIconsRegular.mapPin,
  ),
  MemoToolbarCustomIconOption(
    key: 'mapPinArea',
    label: 'Map Pin Area',
    iconData: PhosphorIconsRegular.mapPinArea,
  ),
  MemoToolbarCustomIconOption(
    key: 'mapPinLine',
    label: 'Map Pin Line',
    iconData: PhosphorIconsRegular.mapPinLine,
  ),
  MemoToolbarCustomIconOption(
    key: 'mapPinPlus',
    label: 'Map Pin Plus',
    iconData: PhosphorIconsRegular.mapPinPlus,
  ),
  MemoToolbarCustomIconOption(
    key: 'mapPinSimple',
    label: 'Map Pin Simple',
    iconData: PhosphorIconsRegular.mapPinSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'mapPinSimpleArea',
    label: 'Map Pin Simple Area',
    iconData: PhosphorIconsRegular.mapPinSimpleArea,
  ),
  MemoToolbarCustomIconOption(
    key: 'mapPinSimpleLine',
    label: 'Map Pin Simple Line',
    iconData: PhosphorIconsRegular.mapPinSimpleLine,
  ),
  MemoToolbarCustomIconOption(
    key: 'mapTrifold',
    label: 'Map Trifold',
    iconData: PhosphorIconsRegular.mapTrifold,
  ),
  MemoToolbarCustomIconOption(
    key: 'markdownLogo',
    label: 'Markdown Logo',
    iconData: PhosphorIconsRegular.markdownLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'markerCircle',
    label: 'Marker Circle',
    iconData: PhosphorIconsRegular.markerCircle,
  ),
  MemoToolbarCustomIconOption(
    key: 'martini',
    label: 'Martini',
    iconData: PhosphorIconsRegular.martini,
  ),
  MemoToolbarCustomIconOption(
    key: 'maskHappy',
    label: 'Mask Happy',
    iconData: PhosphorIconsRegular.maskHappy,
  ),
  MemoToolbarCustomIconOption(
    key: 'maskSad',
    label: 'Mask Sad',
    iconData: PhosphorIconsRegular.maskSad,
  ),
  MemoToolbarCustomIconOption(
    key: 'mastodonLogo',
    label: 'Mastodon Logo',
    iconData: PhosphorIconsRegular.mastodonLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'mathOperations',
    label: 'Math Operations',
    iconData: PhosphorIconsRegular.mathOperations,
  ),
  MemoToolbarCustomIconOption(
    key: 'matrixLogo',
    label: 'Matrix Logo',
    iconData: PhosphorIconsRegular.matrixLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'medal',
    label: 'Medal',
    iconData: PhosphorIconsRegular.medal,
  ),
  MemoToolbarCustomIconOption(
    key: 'medalMilitary',
    label: 'Medal Military',
    iconData: PhosphorIconsRegular.medalMilitary,
  ),
  MemoToolbarCustomIconOption(
    key: 'mediumLogo',
    label: 'Medium Logo',
    iconData: PhosphorIconsRegular.mediumLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'megaphone',
    label: 'Megaphone',
    iconData: PhosphorIconsRegular.megaphone,
  ),
  MemoToolbarCustomIconOption(
    key: 'megaphoneSimple',
    label: 'Megaphone Simple',
    iconData: PhosphorIconsRegular.megaphoneSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'memberOf',
    label: 'Member Of',
    iconData: PhosphorIconsRegular.memberOf,
  ),
  MemoToolbarCustomIconOption(
    key: 'memory',
    label: 'Memory',
    iconData: PhosphorIconsRegular.memory,
  ),
  MemoToolbarCustomIconOption(
    key: 'messengerLogo',
    label: 'Messenger Logo',
    iconData: PhosphorIconsRegular.messengerLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'metaLogo',
    label: 'Meta Logo',
    iconData: PhosphorIconsRegular.metaLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'meteor',
    label: 'Meteor',
    iconData: PhosphorIconsRegular.meteor,
  ),
  MemoToolbarCustomIconOption(
    key: 'metronome',
    label: 'Metronome',
    iconData: PhosphorIconsRegular.metronome,
  ),
  MemoToolbarCustomIconOption(
    key: 'microphone',
    label: 'Microphone',
    iconData: PhosphorIconsRegular.microphone,
  ),
  MemoToolbarCustomIconOption(
    key: 'microphoneSlash',
    label: 'Microphone Slash',
    iconData: PhosphorIconsRegular.microphoneSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'microphoneStage',
    label: 'Microphone Stage',
    iconData: PhosphorIconsRegular.microphoneStage,
  ),
  MemoToolbarCustomIconOption(
    key: 'microscope',
    label: 'Microscope',
    iconData: PhosphorIconsRegular.microscope,
  ),
  MemoToolbarCustomIconOption(
    key: 'microsoftExcelLogo',
    label: 'Microsoft Excel Logo',
    iconData: PhosphorIconsRegular.microsoftExcelLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'microsoftOutlookLogo',
    label: 'Microsoft Outlook Logo',
    iconData: PhosphorIconsRegular.microsoftOutlookLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'microsoftTeamsLogo',
    label: 'Microsoft Teams Logo',
    iconData: PhosphorIconsRegular.microsoftTeamsLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'microsoftWordLogo',
    label: 'Microsoft Word Logo',
    iconData: PhosphorIconsRegular.microsoftWordLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'minus',
    label: 'Minus',
    iconData: PhosphorIconsRegular.minus,
  ),
  MemoToolbarCustomIconOption(
    key: 'minusCircle',
    label: 'Minus Circle',
    iconData: PhosphorIconsRegular.minusCircle,
  ),
  MemoToolbarCustomIconOption(
    key: 'minusSquare',
    label: 'Minus Square',
    iconData: PhosphorIconsRegular.minusSquare,
  ),
  MemoToolbarCustomIconOption(
    key: 'money',
    label: 'Money',
    iconData: PhosphorIconsRegular.money,
  ),
  MemoToolbarCustomIconOption(
    key: 'moneyWavy',
    label: 'Money Wavy',
    iconData: PhosphorIconsRegular.moneyWavy,
  ),
  MemoToolbarCustomIconOption(
    key: 'monitor',
    label: 'Monitor',
    iconData: PhosphorIconsRegular.monitor,
  ),
  MemoToolbarCustomIconOption(
    key: 'monitorArrowUp',
    label: 'Monitor Arrow Up',
    iconData: PhosphorIconsRegular.monitorArrowUp,
  ),
  MemoToolbarCustomIconOption(
    key: 'monitorPlay',
    label: 'Monitor Play',
    iconData: PhosphorIconsRegular.monitorPlay,
  ),
  MemoToolbarCustomIconOption(
    key: 'moon',
    label: 'Moon',
    iconData: PhosphorIconsRegular.moon,
  ),
  MemoToolbarCustomIconOption(
    key: 'moonStars',
    label: 'Moon Stars',
    iconData: PhosphorIconsRegular.moonStars,
  ),
  MemoToolbarCustomIconOption(
    key: 'moped',
    label: 'Moped',
    iconData: PhosphorIconsRegular.moped,
  ),
  MemoToolbarCustomIconOption(
    key: 'mopedFront',
    label: 'Moped Front',
    iconData: PhosphorIconsRegular.mopedFront,
  ),
  MemoToolbarCustomIconOption(
    key: 'mosque',
    label: 'Mosque',
    iconData: PhosphorIconsRegular.mosque,
  ),
  MemoToolbarCustomIconOption(
    key: 'motorcycle',
    label: 'Motorcycle',
    iconData: PhosphorIconsRegular.motorcycle,
  ),
  MemoToolbarCustomIconOption(
    key: 'mountains',
    label: 'Mountains',
    iconData: PhosphorIconsRegular.mountains,
  ),
  MemoToolbarCustomIconOption(
    key: 'mouse',
    label: 'Mouse',
    iconData: PhosphorIconsRegular.mouse,
  ),
  MemoToolbarCustomIconOption(
    key: 'mouseLeftClick',
    label: 'Mouse Left Click',
    iconData: PhosphorIconsRegular.mouseLeftClick,
  ),
  MemoToolbarCustomIconOption(
    key: 'mouseMiddleClick',
    label: 'Mouse Middle Click',
    iconData: PhosphorIconsRegular.mouseMiddleClick,
  ),
  MemoToolbarCustomIconOption(
    key: 'mouseRightClick',
    label: 'Mouse Right Click',
    iconData: PhosphorIconsRegular.mouseRightClick,
  ),
  MemoToolbarCustomIconOption(
    key: 'mouseScroll',
    label: 'Mouse Scroll',
    iconData: PhosphorIconsRegular.mouseScroll,
  ),
  MemoToolbarCustomIconOption(
    key: 'mouseSimple',
    label: 'Mouse Simple',
    iconData: PhosphorIconsRegular.mouseSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'musicNote',
    label: 'Music Note',
    iconData: PhosphorIconsRegular.musicNote,
  ),
  MemoToolbarCustomIconOption(
    key: 'musicNoteSimple',
    label: 'Music Note Simple',
    iconData: PhosphorIconsRegular.musicNoteSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'musicNotes',
    label: 'Music Notes',
    iconData: PhosphorIconsRegular.musicNotes,
  ),
  MemoToolbarCustomIconOption(
    key: 'musicNotesMinus',
    label: 'Music Notes Minus',
    iconData: PhosphorIconsRegular.musicNotesMinus,
  ),
  MemoToolbarCustomIconOption(
    key: 'musicNotesPlus',
    label: 'Music Notes Plus',
    iconData: PhosphorIconsRegular.musicNotesPlus,
  ),
  MemoToolbarCustomIconOption(
    key: 'musicNotesSimple',
    label: 'Music Notes Simple',
    iconData: PhosphorIconsRegular.musicNotesSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'navigationArrow',
    label: 'Navigation Arrow',
    iconData: PhosphorIconsRegular.navigationArrow,
  ),
  MemoToolbarCustomIconOption(
    key: 'needle',
    label: 'Needle',
    iconData: PhosphorIconsRegular.needle,
  ),
  MemoToolbarCustomIconOption(
    key: 'network',
    label: 'Network',
    iconData: PhosphorIconsRegular.network,
  ),
  MemoToolbarCustomIconOption(
    key: 'networkSlash',
    label: 'Network Slash',
    iconData: PhosphorIconsRegular.networkSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'networkX',
    label: 'Network X',
    iconData: PhosphorIconsRegular.networkX,
  ),
  MemoToolbarCustomIconOption(
    key: 'newspaper',
    label: 'Newspaper',
    iconData: PhosphorIconsRegular.newspaper,
  ),
  MemoToolbarCustomIconOption(
    key: 'newspaperClipping',
    label: 'Newspaper Clipping',
    iconData: PhosphorIconsRegular.newspaperClipping,
  ),
  MemoToolbarCustomIconOption(
    key: 'notEquals',
    label: 'Not Equals',
    iconData: PhosphorIconsRegular.notEquals,
  ),
  MemoToolbarCustomIconOption(
    key: 'notMemberOf',
    label: 'Not Member Of',
    iconData: PhosphorIconsRegular.notMemberOf,
  ),
  MemoToolbarCustomIconOption(
    key: 'notSubsetOf',
    label: 'Not Subset Of',
    iconData: PhosphorIconsRegular.notSubsetOf,
  ),
  MemoToolbarCustomIconOption(
    key: 'notSupersetOf',
    label: 'Not Superset Of',
    iconData: PhosphorIconsRegular.notSupersetOf,
  ),
  MemoToolbarCustomIconOption(
    key: 'notches',
    label: 'Notches',
    iconData: PhosphorIconsRegular.notches,
  ),
  MemoToolbarCustomIconOption(
    key: 'note',
    label: 'Note',
    iconData: PhosphorIconsRegular.note,
  ),
  MemoToolbarCustomIconOption(
    key: 'noteBlank',
    label: 'Note Blank',
    iconData: PhosphorIconsRegular.noteBlank,
  ),
  MemoToolbarCustomIconOption(
    key: 'notePencil',
    label: 'Note Pencil',
    iconData: PhosphorIconsRegular.notePencil,
  ),
  MemoToolbarCustomIconOption(
    key: 'notebook',
    label: 'Notebook',
    iconData: PhosphorIconsRegular.notebook,
  ),
  MemoToolbarCustomIconOption(
    key: 'notepad',
    label: 'Notepad',
    iconData: PhosphorIconsRegular.notepad,
  ),
  MemoToolbarCustomIconOption(
    key: 'notification',
    label: 'Notification',
    iconData: PhosphorIconsRegular.notification,
  ),
  MemoToolbarCustomIconOption(
    key: 'notionLogo',
    label: 'Notion Logo',
    iconData: PhosphorIconsRegular.notionLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'nuclearPlant',
    label: 'Nuclear Plant',
    iconData: PhosphorIconsRegular.nuclearPlant,
  ),
  MemoToolbarCustomIconOption(
    key: 'numberCircleEight',
    label: 'Number Circle Eight',
    iconData: PhosphorIconsRegular.numberCircleEight,
  ),
  MemoToolbarCustomIconOption(
    key: 'numberCircleFive',
    label: 'Number Circle Five',
    iconData: PhosphorIconsRegular.numberCircleFive,
  ),
  MemoToolbarCustomIconOption(
    key: 'numberCircleFour',
    label: 'Number Circle Four',
    iconData: PhosphorIconsRegular.numberCircleFour,
  ),
  MemoToolbarCustomIconOption(
    key: 'numberCircleNine',
    label: 'Number Circle Nine',
    iconData: PhosphorIconsRegular.numberCircleNine,
  ),
  MemoToolbarCustomIconOption(
    key: 'numberCircleOne',
    label: 'Number Circle One',
    iconData: PhosphorIconsRegular.numberCircleOne,
  ),
  MemoToolbarCustomIconOption(
    key: 'numberCircleSeven',
    label: 'Number Circle Seven',
    iconData: PhosphorIconsRegular.numberCircleSeven,
  ),
  MemoToolbarCustomIconOption(
    key: 'numberCircleSix',
    label: 'Number Circle Six',
    iconData: PhosphorIconsRegular.numberCircleSix,
  ),
  MemoToolbarCustomIconOption(
    key: 'numberCircleThree',
    label: 'Number Circle Three',
    iconData: PhosphorIconsRegular.numberCircleThree,
  ),
  MemoToolbarCustomIconOption(
    key: 'numberCircleTwo',
    label: 'Number Circle Two',
    iconData: PhosphorIconsRegular.numberCircleTwo,
  ),
  MemoToolbarCustomIconOption(
    key: 'numberCircleZero',
    label: 'Number Circle Zero',
    iconData: PhosphorIconsRegular.numberCircleZero,
  ),
  MemoToolbarCustomIconOption(
    key: 'numberEight',
    label: 'Number Eight',
    iconData: PhosphorIconsRegular.numberEight,
  ),
  MemoToolbarCustomIconOption(
    key: 'numberFive',
    label: 'Number Five',
    iconData: PhosphorIconsRegular.numberFive,
  ),
  MemoToolbarCustomIconOption(
    key: 'numberFour',
    label: 'Number Four',
    iconData: PhosphorIconsRegular.numberFour,
  ),
  MemoToolbarCustomIconOption(
    key: 'numberNine',
    label: 'Number Nine',
    iconData: PhosphorIconsRegular.numberNine,
  ),
  MemoToolbarCustomIconOption(
    key: 'numberOne',
    label: 'Number One',
    iconData: PhosphorIconsRegular.numberOne,
  ),
  MemoToolbarCustomIconOption(
    key: 'numberSeven',
    label: 'Number Seven',
    iconData: PhosphorIconsRegular.numberSeven,
  ),
  MemoToolbarCustomIconOption(
    key: 'numberSix',
    label: 'Number Six',
    iconData: PhosphorIconsRegular.numberSix,
  ),
  MemoToolbarCustomIconOption(
    key: 'numberSquareEight',
    label: 'Number Square Eight',
    iconData: PhosphorIconsRegular.numberSquareEight,
  ),
  MemoToolbarCustomIconOption(
    key: 'numberSquareFive',
    label: 'Number Square Five',
    iconData: PhosphorIconsRegular.numberSquareFive,
  ),
  MemoToolbarCustomIconOption(
    key: 'numberSquareFour',
    label: 'Number Square Four',
    iconData: PhosphorIconsRegular.numberSquareFour,
  ),
  MemoToolbarCustomIconOption(
    key: 'numberSquareNine',
    label: 'Number Square Nine',
    iconData: PhosphorIconsRegular.numberSquareNine,
  ),
  MemoToolbarCustomIconOption(
    key: 'numberSquareOne',
    label: 'Number Square One',
    iconData: PhosphorIconsRegular.numberSquareOne,
  ),
  MemoToolbarCustomIconOption(
    key: 'numberSquareSeven',
    label: 'Number Square Seven',
    iconData: PhosphorIconsRegular.numberSquareSeven,
  ),
  MemoToolbarCustomIconOption(
    key: 'numberSquareSix',
    label: 'Number Square Six',
    iconData: PhosphorIconsRegular.numberSquareSix,
  ),
  MemoToolbarCustomIconOption(
    key: 'numberSquareThree',
    label: 'Number Square Three',
    iconData: PhosphorIconsRegular.numberSquareThree,
  ),
  MemoToolbarCustomIconOption(
    key: 'numberSquareTwo',
    label: 'Number Square Two',
    iconData: PhosphorIconsRegular.numberSquareTwo,
  ),
  MemoToolbarCustomIconOption(
    key: 'numberSquareZero',
    label: 'Number Square Zero',
    iconData: PhosphorIconsRegular.numberSquareZero,
  ),
  MemoToolbarCustomIconOption(
    key: 'numberThree',
    label: 'Number Three',
    iconData: PhosphorIconsRegular.numberThree,
  ),
  MemoToolbarCustomIconOption(
    key: 'numberTwo',
    label: 'Number Two',
    iconData: PhosphorIconsRegular.numberTwo,
  ),
  MemoToolbarCustomIconOption(
    key: 'numberZero',
    label: 'Number Zero',
    iconData: PhosphorIconsRegular.numberZero,
  ),
  MemoToolbarCustomIconOption(
    key: 'numpad',
    label: 'Numpad',
    iconData: PhosphorIconsRegular.numpad,
  ),
  MemoToolbarCustomIconOption(
    key: 'nut',
    label: 'Nut',
    iconData: PhosphorIconsRegular.nut,
  ),
  MemoToolbarCustomIconOption(
    key: 'nyTimesLogo',
    label: 'Ny Times Logo',
    iconData: PhosphorIconsRegular.nyTimesLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'octagon',
    label: 'Octagon',
    iconData: PhosphorIconsRegular.octagon,
  ),
  MemoToolbarCustomIconOption(
    key: 'officeChair',
    label: 'Office Chair',
    iconData: PhosphorIconsRegular.officeChair,
  ),
  MemoToolbarCustomIconOption(
    key: 'onigiri',
    label: 'Onigiri',
    iconData: PhosphorIconsRegular.onigiri,
  ),
  MemoToolbarCustomIconOption(
    key: 'openAiLogo',
    label: 'Open Ai Logo',
    iconData: PhosphorIconsRegular.openAiLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'option',
    label: 'Option',
    iconData: PhosphorIconsRegular.option,
  ),
  MemoToolbarCustomIconOption(
    key: 'orange',
    label: 'Orange',
    iconData: PhosphorIconsRegular.orange,
  ),
  MemoToolbarCustomIconOption(
    key: 'orangeSlice',
    label: 'Orange Slice',
    iconData: PhosphorIconsRegular.orangeSlice,
  ),
  MemoToolbarCustomIconOption(
    key: 'oven',
    label: 'Oven',
    iconData: PhosphorIconsRegular.oven,
  ),
  MemoToolbarCustomIconOption(
    key: 'package',
    label: 'Package',
    iconData: PhosphorIconsRegular.package,
  ),
  MemoToolbarCustomIconOption(
    key: 'paintBrush',
    label: 'Paint Brush',
    iconData: PhosphorIconsRegular.paintBrush,
  ),
  MemoToolbarCustomIconOption(
    key: 'paintBrushBroad',
    label: 'Paint Brush Broad',
    iconData: PhosphorIconsRegular.paintBrushBroad,
  ),
  MemoToolbarCustomIconOption(
    key: 'paintBrushHousehold',
    label: 'Paint Brush Household',
    iconData: PhosphorIconsRegular.paintBrushHousehold,
  ),
  MemoToolbarCustomIconOption(
    key: 'paintBucket',
    label: 'Paint Bucket',
    iconData: PhosphorIconsRegular.paintBucket,
  ),
  MemoToolbarCustomIconOption(
    key: 'paintRoller',
    label: 'Paint Roller',
    iconData: PhosphorIconsRegular.paintRoller,
  ),
  MemoToolbarCustomIconOption(
    key: 'palette',
    label: 'Palette',
    iconData: PhosphorIconsRegular.palette,
  ),
  MemoToolbarCustomIconOption(
    key: 'panorama',
    label: 'Panorama',
    iconData: PhosphorIconsRegular.panorama,
  ),
  MemoToolbarCustomIconOption(
    key: 'pants',
    label: 'Pants',
    iconData: PhosphorIconsRegular.pants,
  ),
  MemoToolbarCustomIconOption(
    key: 'paperPlane',
    label: 'Paper Plane',
    iconData: PhosphorIconsRegular.paperPlane,
  ),
  MemoToolbarCustomIconOption(
    key: 'paperPlaneRight',
    label: 'Paper Plane Right',
    iconData: PhosphorIconsRegular.paperPlaneRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'paperPlaneTilt',
    label: 'Paper Plane Tilt',
    iconData: PhosphorIconsRegular.paperPlaneTilt,
  ),
  MemoToolbarCustomIconOption(
    key: 'paperclip',
    label: 'Paperclip',
    iconData: PhosphorIconsRegular.paperclip,
  ),
  MemoToolbarCustomIconOption(
    key: 'paperclipHorizontal',
    label: 'Paperclip Horizontal',
    iconData: PhosphorIconsRegular.paperclipHorizontal,
  ),
  MemoToolbarCustomIconOption(
    key: 'parachute',
    label: 'Parachute',
    iconData: PhosphorIconsRegular.parachute,
  ),
  MemoToolbarCustomIconOption(
    key: 'paragraph',
    label: 'Paragraph',
    iconData: PhosphorIconsRegular.paragraph,
  ),
  MemoToolbarCustomIconOption(
    key: 'parallelogram',
    label: 'Parallelogram',
    iconData: PhosphorIconsRegular.parallelogram,
  ),
  MemoToolbarCustomIconOption(
    key: 'park',
    label: 'Park',
    iconData: PhosphorIconsRegular.park,
  ),
  MemoToolbarCustomIconOption(
    key: 'password',
    label: 'Password',
    iconData: PhosphorIconsRegular.password,
  ),
  MemoToolbarCustomIconOption(
    key: 'path',
    label: 'Path',
    iconData: PhosphorIconsRegular.path,
  ),
  MemoToolbarCustomIconOption(
    key: 'patreonLogo',
    label: 'Patreon Logo',
    iconData: PhosphorIconsRegular.patreonLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'pause',
    label: 'Pause',
    iconData: PhosphorIconsRegular.pause,
  ),
  MemoToolbarCustomIconOption(
    key: 'pauseCircle',
    label: 'Pause Circle',
    iconData: PhosphorIconsRegular.pauseCircle,
  ),
  MemoToolbarCustomIconOption(
    key: 'pawPrint',
    label: 'Paw Print',
    iconData: PhosphorIconsRegular.pawPrint,
  ),
  MemoToolbarCustomIconOption(
    key: 'paypalLogo',
    label: 'Paypal Logo',
    iconData: PhosphorIconsRegular.paypalLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'peace',
    label: 'Peace',
    iconData: PhosphorIconsRegular.peace,
  ),
  MemoToolbarCustomIconOption(
    key: 'pen',
    label: 'Pen',
    iconData: PhosphorIconsRegular.pen,
  ),
  MemoToolbarCustomIconOption(
    key: 'penNib',
    label: 'Pen Nib',
    iconData: PhosphorIconsRegular.penNib,
  ),
  MemoToolbarCustomIconOption(
    key: 'penNibStraight',
    label: 'Pen Nib Straight',
    iconData: PhosphorIconsRegular.penNibStraight,
  ),
  MemoToolbarCustomIconOption(
    key: 'pencil',
    label: 'Pencil',
    iconData: PhosphorIconsRegular.pencil,
  ),
  MemoToolbarCustomIconOption(
    key: 'pencilCircle',
    label: 'Pencil Circle',
    iconData: PhosphorIconsRegular.pencilCircle,
  ),
  MemoToolbarCustomIconOption(
    key: 'pencilLine',
    label: 'Pencil Line',
    iconData: PhosphorIconsRegular.pencilLine,
  ),
  MemoToolbarCustomIconOption(
    key: 'pencilRuler',
    label: 'Pencil Ruler',
    iconData: PhosphorIconsRegular.pencilRuler,
  ),
  MemoToolbarCustomIconOption(
    key: 'pencilSimple',
    label: 'Pencil Simple',
    iconData: PhosphorIconsRegular.pencilSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'pencilSimpleLine',
    label: 'Pencil Simple Line',
    iconData: PhosphorIconsRegular.pencilSimpleLine,
  ),
  MemoToolbarCustomIconOption(
    key: 'pencilSimpleSlash',
    label: 'Pencil Simple Slash',
    iconData: PhosphorIconsRegular.pencilSimpleSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'pencilSlash',
    label: 'Pencil Slash',
    iconData: PhosphorIconsRegular.pencilSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'pentagon',
    label: 'Pentagon',
    iconData: PhosphorIconsRegular.pentagon,
  ),
  MemoToolbarCustomIconOption(
    key: 'pentagram',
    label: 'Pentagram',
    iconData: PhosphorIconsRegular.pentagram,
  ),
  MemoToolbarCustomIconOption(
    key: 'pepper',
    label: 'Pepper',
    iconData: PhosphorIconsRegular.pepper,
  ),
  MemoToolbarCustomIconOption(
    key: 'percent',
    label: 'Percent',
    iconData: PhosphorIconsRegular.percent,
  ),
  MemoToolbarCustomIconOption(
    key: 'person',
    label: 'Person',
    iconData: PhosphorIconsRegular.person,
  ),
  MemoToolbarCustomIconOption(
    key: 'personArmsSpread',
    label: 'Person Arms Spread',
    iconData: PhosphorIconsRegular.personArmsSpread,
  ),
  MemoToolbarCustomIconOption(
    key: 'personSimple',
    label: 'Person Simple',
    iconData: PhosphorIconsRegular.personSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'personSimpleBike',
    label: 'Person Simple Bike',
    iconData: PhosphorIconsRegular.personSimpleBike,
  ),
  MemoToolbarCustomIconOption(
    key: 'personSimpleCircle',
    label: 'Person Simple Circle',
    iconData: PhosphorIconsRegular.personSimpleCircle,
  ),
  MemoToolbarCustomIconOption(
    key: 'personSimpleHike',
    label: 'Person Simple Hike',
    iconData: PhosphorIconsRegular.personSimpleHike,
  ),
  MemoToolbarCustomIconOption(
    key: 'personSimpleRun',
    label: 'Person Simple Run',
    iconData: PhosphorIconsRegular.personSimpleRun,
  ),
  MemoToolbarCustomIconOption(
    key: 'personSimpleSki',
    label: 'Person Simple Ski',
    iconData: PhosphorIconsRegular.personSimpleSki,
  ),
  MemoToolbarCustomIconOption(
    key: 'personSimpleSnowboard',
    label: 'Person Simple Snowboard',
    iconData: PhosphorIconsRegular.personSimpleSnowboard,
  ),
  MemoToolbarCustomIconOption(
    key: 'personSimpleSwim',
    label: 'Person Simple Swim',
    iconData: PhosphorIconsRegular.personSimpleSwim,
  ),
  MemoToolbarCustomIconOption(
    key: 'personSimpleTaiChi',
    label: 'Person Simple Tai Chi',
    iconData: PhosphorIconsRegular.personSimpleTaiChi,
  ),
  MemoToolbarCustomIconOption(
    key: 'personSimpleThrow',
    label: 'Person Simple Throw',
    iconData: PhosphorIconsRegular.personSimpleThrow,
  ),
  MemoToolbarCustomIconOption(
    key: 'personSimpleWalk',
    label: 'Person Simple Walk',
    iconData: PhosphorIconsRegular.personSimpleWalk,
  ),
  MemoToolbarCustomIconOption(
    key: 'perspective',
    label: 'Perspective',
    iconData: PhosphorIconsRegular.perspective,
  ),
  MemoToolbarCustomIconOption(
    key: 'phone',
    label: 'Phone',
    iconData: PhosphorIconsRegular.phone,
  ),
  MemoToolbarCustomIconOption(
    key: 'phoneCall',
    label: 'Phone Call',
    iconData: PhosphorIconsRegular.phoneCall,
  ),
  MemoToolbarCustomIconOption(
    key: 'phoneDisconnect',
    label: 'Phone Disconnect',
    iconData: PhosphorIconsRegular.phoneDisconnect,
  ),
  MemoToolbarCustomIconOption(
    key: 'phoneIncoming',
    label: 'Phone Incoming',
    iconData: PhosphorIconsRegular.phoneIncoming,
  ),
  MemoToolbarCustomIconOption(
    key: 'phoneList',
    label: 'Phone List',
    iconData: PhosphorIconsRegular.phoneList,
  ),
  MemoToolbarCustomIconOption(
    key: 'phoneOutgoing',
    label: 'Phone Outgoing',
    iconData: PhosphorIconsRegular.phoneOutgoing,
  ),
  MemoToolbarCustomIconOption(
    key: 'phonePause',
    label: 'Phone Pause',
    iconData: PhosphorIconsRegular.phonePause,
  ),
  MemoToolbarCustomIconOption(
    key: 'phonePlus',
    label: 'Phone Plus',
    iconData: PhosphorIconsRegular.phonePlus,
  ),
  MemoToolbarCustomIconOption(
    key: 'phoneSlash',
    label: 'Phone Slash',
    iconData: PhosphorIconsRegular.phoneSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'phoneTransfer',
    label: 'Phone Transfer',
    iconData: PhosphorIconsRegular.phoneTransfer,
  ),
  MemoToolbarCustomIconOption(
    key: 'phoneX',
    label: 'Phone X',
    iconData: PhosphorIconsRegular.phoneX,
  ),
  MemoToolbarCustomIconOption(
    key: 'phosphorLogo',
    label: 'Phosphor Logo',
    iconData: PhosphorIconsRegular.phosphorLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'pi',
    label: 'Pi',
    iconData: PhosphorIconsRegular.pi,
  ),
  MemoToolbarCustomIconOption(
    key: 'pianoKeys',
    label: 'Piano Keys',
    iconData: PhosphorIconsRegular.pianoKeys,
  ),
  MemoToolbarCustomIconOption(
    key: 'picnicTable',
    label: 'Picnic Table',
    iconData: PhosphorIconsRegular.picnicTable,
  ),
  MemoToolbarCustomIconOption(
    key: 'pictureInpicture',
    label: 'Picture Inpicture',
    iconData: PhosphorIconsRegular.pictureInpicture,
  ),
  MemoToolbarCustomIconOption(
    key: 'piggyBank',
    label: 'Piggy Bank',
    iconData: PhosphorIconsRegular.piggyBank,
  ),
  MemoToolbarCustomIconOption(
    key: 'pill',
    label: 'Pill',
    iconData: PhosphorIconsRegular.pill,
  ),
  MemoToolbarCustomIconOption(
    key: 'pingPong',
    label: 'Ping Pong',
    iconData: PhosphorIconsRegular.pingPong,
  ),
  MemoToolbarCustomIconOption(
    key: 'pintGlass',
    label: 'Pint Glass',
    iconData: PhosphorIconsRegular.pintGlass,
  ),
  MemoToolbarCustomIconOption(
    key: 'pinterestLogo',
    label: 'Pinterest Logo',
    iconData: PhosphorIconsRegular.pinterestLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'pinwheel',
    label: 'Pinwheel',
    iconData: PhosphorIconsRegular.pinwheel,
  ),
  MemoToolbarCustomIconOption(
    key: 'pipe',
    label: 'Pipe',
    iconData: PhosphorIconsRegular.pipe,
  ),
  MemoToolbarCustomIconOption(
    key: 'pipeWrench',
    label: 'Pipe Wrench',
    iconData: PhosphorIconsRegular.pipeWrench,
  ),
  MemoToolbarCustomIconOption(
    key: 'pixLogo',
    label: 'Pix Logo',
    iconData: PhosphorIconsRegular.pixLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'pizza',
    label: 'Pizza',
    iconData: PhosphorIconsRegular.pizza,
  ),
  MemoToolbarCustomIconOption(
    key: 'placeholder',
    label: 'Placeholder',
    iconData: PhosphorIconsRegular.placeholder,
  ),
  MemoToolbarCustomIconOption(
    key: 'planet',
    label: 'Planet',
    iconData: PhosphorIconsRegular.planet,
  ),
  MemoToolbarCustomIconOption(
    key: 'plant',
    label: 'Plant',
    iconData: PhosphorIconsRegular.plant,
  ),
  MemoToolbarCustomIconOption(
    key: 'play',
    label: 'Play',
    iconData: PhosphorIconsRegular.play,
  ),
  MemoToolbarCustomIconOption(
    key: 'playCircle',
    label: 'Play Circle',
    iconData: PhosphorIconsRegular.playCircle,
  ),
  MemoToolbarCustomIconOption(
    key: 'playPause',
    label: 'Play Pause',
    iconData: PhosphorIconsRegular.playPause,
  ),
  MemoToolbarCustomIconOption(
    key: 'playlist',
    label: 'Playlist',
    iconData: PhosphorIconsRegular.playlist,
  ),
  MemoToolbarCustomIconOption(
    key: 'plug',
    label: 'Plug',
    iconData: PhosphorIconsRegular.plug,
  ),
  MemoToolbarCustomIconOption(
    key: 'plugCharging',
    label: 'Plug Charging',
    iconData: PhosphorIconsRegular.plugCharging,
  ),
  MemoToolbarCustomIconOption(
    key: 'plugs',
    label: 'Plugs',
    iconData: PhosphorIconsRegular.plugs,
  ),
  MemoToolbarCustomIconOption(
    key: 'plugsConnected',
    label: 'Plugs Connected',
    iconData: PhosphorIconsRegular.plugsConnected,
  ),
  MemoToolbarCustomIconOption(
    key: 'plus',
    label: 'Plus',
    iconData: PhosphorIconsRegular.plus,
  ),
  MemoToolbarCustomIconOption(
    key: 'plusCircle',
    label: 'Plus Circle',
    iconData: PhosphorIconsRegular.plusCircle,
  ),
  MemoToolbarCustomIconOption(
    key: 'plusMinus',
    label: 'Plus Minus',
    iconData: PhosphorIconsRegular.plusMinus,
  ),
  MemoToolbarCustomIconOption(
    key: 'plusSquare',
    label: 'Plus Square',
    iconData: PhosphorIconsRegular.plusSquare,
  ),
  MemoToolbarCustomIconOption(
    key: 'pokerChip',
    label: 'Poker Chip',
    iconData: PhosphorIconsRegular.pokerChip,
  ),
  MemoToolbarCustomIconOption(
    key: 'policeCar',
    label: 'Police Car',
    iconData: PhosphorIconsRegular.policeCar,
  ),
  MemoToolbarCustomIconOption(
    key: 'polygon',
    label: 'Polygon',
    iconData: PhosphorIconsRegular.polygon,
  ),
  MemoToolbarCustomIconOption(
    key: 'popcorn',
    label: 'Popcorn',
    iconData: PhosphorIconsRegular.popcorn,
  ),
  MemoToolbarCustomIconOption(
    key: 'popsicle',
    label: 'Popsicle',
    iconData: PhosphorIconsRegular.popsicle,
  ),
  MemoToolbarCustomIconOption(
    key: 'pottedPlant',
    label: 'Potted Plant',
    iconData: PhosphorIconsRegular.pottedPlant,
  ),
  MemoToolbarCustomIconOption(
    key: 'power',
    label: 'Power',
    iconData: PhosphorIconsRegular.power,
  ),
  MemoToolbarCustomIconOption(
    key: 'prescription',
    label: 'Prescription',
    iconData: PhosphorIconsRegular.prescription,
  ),
  MemoToolbarCustomIconOption(
    key: 'presentation',
    label: 'Presentation',
    iconData: PhosphorIconsRegular.presentation,
  ),
  MemoToolbarCustomIconOption(
    key: 'presentationChart',
    label: 'Presentation Chart',
    iconData: PhosphorIconsRegular.presentationChart,
  ),
  MemoToolbarCustomIconOption(
    key: 'printer',
    label: 'Printer',
    iconData: PhosphorIconsRegular.printer,
  ),
  MemoToolbarCustomIconOption(
    key: 'prohibit',
    label: 'Prohibit',
    iconData: PhosphorIconsRegular.prohibit,
  ),
  MemoToolbarCustomIconOption(
    key: 'prohibitInset',
    label: 'Prohibit Inset',
    iconData: PhosphorIconsRegular.prohibitInset,
  ),
  MemoToolbarCustomIconOption(
    key: 'projectorScreen',
    label: 'Projector Screen',
    iconData: PhosphorIconsRegular.projectorScreen,
  ),
  MemoToolbarCustomIconOption(
    key: 'projectorScreenChart',
    label: 'Projector Screen Chart',
    iconData: PhosphorIconsRegular.projectorScreenChart,
  ),
  MemoToolbarCustomIconOption(
    key: 'pulse',
    label: 'Pulse',
    iconData: PhosphorIconsRegular.pulse,
  ),
  MemoToolbarCustomIconOption(
    key: 'pushPin',
    label: 'Push Pin',
    iconData: PhosphorIconsRegular.pushPin,
  ),
  MemoToolbarCustomIconOption(
    key: 'pushPinSimple',
    label: 'Push Pin Simple',
    iconData: PhosphorIconsRegular.pushPinSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'pushPinSimpleSlash',
    label: 'Push Pin Simple Slash',
    iconData: PhosphorIconsRegular.pushPinSimpleSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'pushPinSlash',
    label: 'Push Pin Slash',
    iconData: PhosphorIconsRegular.pushPinSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'puzzlePiece',
    label: 'Puzzle Piece',
    iconData: PhosphorIconsRegular.puzzlePiece,
  ),
  MemoToolbarCustomIconOption(
    key: 'qrCode',
    label: 'Qr Code',
    iconData: PhosphorIconsRegular.qrCode,
  ),
  MemoToolbarCustomIconOption(
    key: 'question',
    label: 'Question',
    iconData: PhosphorIconsRegular.question,
  ),
  MemoToolbarCustomIconOption(
    key: 'questionMark',
    label: 'Question Mark',
    iconData: PhosphorIconsRegular.questionMark,
  ),
  MemoToolbarCustomIconOption(
    key: 'queue',
    label: 'Queue',
    iconData: PhosphorIconsRegular.queue,
  ),
  MemoToolbarCustomIconOption(
    key: 'quotes',
    label: 'Quotes',
    iconData: PhosphorIconsRegular.quotes,
  ),
  MemoToolbarCustomIconOption(
    key: 'rabbit',
    label: 'Rabbit',
    iconData: PhosphorIconsRegular.rabbit,
  ),
  MemoToolbarCustomIconOption(
    key: 'racquet',
    label: 'Racquet',
    iconData: PhosphorIconsRegular.racquet,
  ),
  MemoToolbarCustomIconOption(
    key: 'radical',
    label: 'Radical',
    iconData: PhosphorIconsRegular.radical,
  ),
  MemoToolbarCustomIconOption(
    key: 'radio',
    label: 'Radio',
    iconData: PhosphorIconsRegular.radio,
  ),
  MemoToolbarCustomIconOption(
    key: 'radioButton',
    label: 'Radio Button',
    iconData: PhosphorIconsRegular.radioButton,
  ),
  MemoToolbarCustomIconOption(
    key: 'radioactive',
    label: 'Radioactive',
    iconData: PhosphorIconsRegular.radioactive,
  ),
  MemoToolbarCustomIconOption(
    key: 'rainbow',
    label: 'Rainbow',
    iconData: PhosphorIconsRegular.rainbow,
  ),
  MemoToolbarCustomIconOption(
    key: 'rainbowCloud',
    label: 'Rainbow Cloud',
    iconData: PhosphorIconsRegular.rainbowCloud,
  ),
  MemoToolbarCustomIconOption(
    key: 'ranking',
    label: 'Ranking',
    iconData: PhosphorIconsRegular.ranking,
  ),
  MemoToolbarCustomIconOption(
    key: 'readCvLogo',
    label: 'Read Cv Logo',
    iconData: PhosphorIconsRegular.readCvLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'receipt',
    label: 'Receipt',
    iconData: PhosphorIconsRegular.receipt,
  ),
  MemoToolbarCustomIconOption(
    key: 'receiptX',
    label: 'Receipt X',
    iconData: PhosphorIconsRegular.receiptX,
  ),
  MemoToolbarCustomIconOption(
    key: 'record',
    label: 'Record',
    iconData: PhosphorIconsRegular.record,
  ),
  MemoToolbarCustomIconOption(
    key: 'rectangle',
    label: 'Rectangle',
    iconData: PhosphorIconsRegular.rectangle,
  ),
  MemoToolbarCustomIconOption(
    key: 'rectangleDashed',
    label: 'Rectangle Dashed',
    iconData: PhosphorIconsRegular.rectangleDashed,
  ),
  MemoToolbarCustomIconOption(
    key: 'recycle',
    label: 'Recycle',
    iconData: PhosphorIconsRegular.recycle,
  ),
  MemoToolbarCustomIconOption(
    key: 'redditLogo',
    label: 'Reddit Logo',
    iconData: PhosphorIconsRegular.redditLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'repeat',
    label: 'Repeat',
    iconData: PhosphorIconsRegular.repeat,
  ),
  MemoToolbarCustomIconOption(
    key: 'repeatOnce',
    label: 'Repeat Once',
    iconData: PhosphorIconsRegular.repeatOnce,
  ),
  MemoToolbarCustomIconOption(
    key: 'replitLogo',
    label: 'Replit Logo',
    iconData: PhosphorIconsRegular.replitLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'resize',
    label: 'Resize',
    iconData: PhosphorIconsRegular.resize,
  ),
  MemoToolbarCustomIconOption(
    key: 'rewind',
    label: 'Rewind',
    iconData: PhosphorIconsRegular.rewind,
  ),
  MemoToolbarCustomIconOption(
    key: 'rewindCircle',
    label: 'Rewind Circle',
    iconData: PhosphorIconsRegular.rewindCircle,
  ),
  MemoToolbarCustomIconOption(
    key: 'roadHorizon',
    label: 'Road Horizon',
    iconData: PhosphorIconsRegular.roadHorizon,
  ),
  MemoToolbarCustomIconOption(
    key: 'robot',
    label: 'Robot',
    iconData: PhosphorIconsRegular.robot,
  ),
  MemoToolbarCustomIconOption(
    key: 'rocket',
    label: 'Rocket',
    iconData: PhosphorIconsRegular.rocket,
  ),
  MemoToolbarCustomIconOption(
    key: 'rocketLaunch',
    label: 'Rocket Launch',
    iconData: PhosphorIconsRegular.rocketLaunch,
  ),
  MemoToolbarCustomIconOption(
    key: 'rows',
    label: 'Rows',
    iconData: PhosphorIconsRegular.rows,
  ),
  MemoToolbarCustomIconOption(
    key: 'rowsPlusBottom',
    label: 'Rows Plus Bottom',
    iconData: PhosphorIconsRegular.rowsPlusBottom,
  ),
  MemoToolbarCustomIconOption(
    key: 'rowsPlusTop',
    label: 'Rows Plus Top',
    iconData: PhosphorIconsRegular.rowsPlusTop,
  ),
  MemoToolbarCustomIconOption(
    key: 'rss',
    label: 'Rss',
    iconData: PhosphorIconsRegular.rss,
  ),
  MemoToolbarCustomIconOption(
    key: 'rssSimple',
    label: 'Rss Simple',
    iconData: PhosphorIconsRegular.rssSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'rug',
    label: 'Rug',
    iconData: PhosphorIconsRegular.rug,
  ),
  MemoToolbarCustomIconOption(
    key: 'ruler',
    label: 'Ruler',
    iconData: PhosphorIconsRegular.ruler,
  ),
  MemoToolbarCustomIconOption(
    key: 'sailboat',
    label: 'Sailboat',
    iconData: PhosphorIconsRegular.sailboat,
  ),
  MemoToolbarCustomIconOption(
    key: 'scales',
    label: 'Scales',
    iconData: PhosphorIconsRegular.scales,
  ),
  MemoToolbarCustomIconOption(
    key: 'scan',
    label: 'Scan',
    iconData: PhosphorIconsRegular.scan,
  ),
  MemoToolbarCustomIconOption(
    key: 'scanSmiley',
    label: 'Scan Smiley',
    iconData: PhosphorIconsRegular.scanSmiley,
  ),
  MemoToolbarCustomIconOption(
    key: 'scissors',
    label: 'Scissors',
    iconData: PhosphorIconsRegular.scissors,
  ),
  MemoToolbarCustomIconOption(
    key: 'scooter',
    label: 'Scooter',
    iconData: PhosphorIconsRegular.scooter,
  ),
  MemoToolbarCustomIconOption(
    key: 'screencast',
    label: 'Screencast',
    iconData: PhosphorIconsRegular.screencast,
  ),
  MemoToolbarCustomIconOption(
    key: 'screwdriver',
    label: 'Screwdriver',
    iconData: PhosphorIconsRegular.screwdriver,
  ),
  MemoToolbarCustomIconOption(
    key: 'scribble',
    label: 'Scribble',
    iconData: PhosphorIconsRegular.scribble,
  ),
  MemoToolbarCustomIconOption(
    key: 'scribbleLoop',
    label: 'Scribble Loop',
    iconData: PhosphorIconsRegular.scribbleLoop,
  ),
  MemoToolbarCustomIconOption(
    key: 'scroll',
    label: 'Scroll',
    iconData: PhosphorIconsRegular.scroll,
  ),
  MemoToolbarCustomIconOption(
    key: 'seal',
    label: 'Seal',
    iconData: PhosphorIconsRegular.seal,
  ),
  MemoToolbarCustomIconOption(
    key: 'sealCheck',
    label: 'Seal Check',
    iconData: PhosphorIconsRegular.sealCheck,
  ),
  MemoToolbarCustomIconOption(
    key: 'sealPercent',
    label: 'Seal Percent',
    iconData: PhosphorIconsRegular.sealPercent,
  ),
  MemoToolbarCustomIconOption(
    key: 'sealQuestion',
    label: 'Seal Question',
    iconData: PhosphorIconsRegular.sealQuestion,
  ),
  MemoToolbarCustomIconOption(
    key: 'sealWarning',
    label: 'Seal Warning',
    iconData: PhosphorIconsRegular.sealWarning,
  ),
  MemoToolbarCustomIconOption(
    key: 'seat',
    label: 'Seat',
    iconData: PhosphorIconsRegular.seat,
  ),
  MemoToolbarCustomIconOption(
    key: 'seatbelt',
    label: 'Seatbelt',
    iconData: PhosphorIconsRegular.seatbelt,
  ),
  MemoToolbarCustomIconOption(
    key: 'securityCamera',
    label: 'Security Camera',
    iconData: PhosphorIconsRegular.securityCamera,
  ),
  MemoToolbarCustomIconOption(
    key: 'selection',
    label: 'Selection',
    iconData: PhosphorIconsRegular.selection,
  ),
  MemoToolbarCustomIconOption(
    key: 'selectionAll',
    label: 'Selection All',
    iconData: PhosphorIconsRegular.selectionAll,
  ),
  MemoToolbarCustomIconOption(
    key: 'selectionBackground',
    label: 'Selection Background',
    iconData: PhosphorIconsRegular.selectionBackground,
  ),
  MemoToolbarCustomIconOption(
    key: 'selectionForeground',
    label: 'Selection Foreground',
    iconData: PhosphorIconsRegular.selectionForeground,
  ),
  MemoToolbarCustomIconOption(
    key: 'selectionInverse',
    label: 'Selection Inverse',
    iconData: PhosphorIconsRegular.selectionInverse,
  ),
  MemoToolbarCustomIconOption(
    key: 'selectionPlus',
    label: 'Selection Plus',
    iconData: PhosphorIconsRegular.selectionPlus,
  ),
  MemoToolbarCustomIconOption(
    key: 'selectionSlash',
    label: 'Selection Slash',
    iconData: PhosphorIconsRegular.selectionSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'shapes',
    label: 'Shapes',
    iconData: PhosphorIconsRegular.shapes,
  ),
  MemoToolbarCustomIconOption(
    key: 'share',
    label: 'Share',
    iconData: PhosphorIconsRegular.share,
  ),
  MemoToolbarCustomIconOption(
    key: 'shareFat',
    label: 'Share Fat',
    iconData: PhosphorIconsRegular.shareFat,
  ),
  MemoToolbarCustomIconOption(
    key: 'shareNetwork',
    label: 'Share Network',
    iconData: PhosphorIconsRegular.shareNetwork,
  ),
  MemoToolbarCustomIconOption(
    key: 'shield',
    label: 'Shield',
    iconData: PhosphorIconsRegular.shield,
  ),
  MemoToolbarCustomIconOption(
    key: 'shieldCheck',
    label: 'Shield Check',
    iconData: PhosphorIconsRegular.shieldCheck,
  ),
  MemoToolbarCustomIconOption(
    key: 'shieldCheckered',
    label: 'Shield Checkered',
    iconData: PhosphorIconsRegular.shieldCheckered,
  ),
  MemoToolbarCustomIconOption(
    key: 'shieldChevron',
    label: 'Shield Chevron',
    iconData: PhosphorIconsRegular.shieldChevron,
  ),
  MemoToolbarCustomIconOption(
    key: 'shieldPlus',
    label: 'Shield Plus',
    iconData: PhosphorIconsRegular.shieldPlus,
  ),
  MemoToolbarCustomIconOption(
    key: 'shieldSlash',
    label: 'Shield Slash',
    iconData: PhosphorIconsRegular.shieldSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'shieldStar',
    label: 'Shield Star',
    iconData: PhosphorIconsRegular.shieldStar,
  ),
  MemoToolbarCustomIconOption(
    key: 'shieldWarning',
    label: 'Shield Warning',
    iconData: PhosphorIconsRegular.shieldWarning,
  ),
  MemoToolbarCustomIconOption(
    key: 'shippingContainer',
    label: 'Shipping Container',
    iconData: PhosphorIconsRegular.shippingContainer,
  ),
  MemoToolbarCustomIconOption(
    key: 'shirtFolded',
    label: 'Shirt Folded',
    iconData: PhosphorIconsRegular.shirtFolded,
  ),
  MemoToolbarCustomIconOption(
    key: 'shootingStar',
    label: 'Shooting Star',
    iconData: PhosphorIconsRegular.shootingStar,
  ),
  MemoToolbarCustomIconOption(
    key: 'shoppingBag',
    label: 'Shopping Bag',
    iconData: PhosphorIconsRegular.shoppingBag,
  ),
  MemoToolbarCustomIconOption(
    key: 'shoppingBagOpen',
    label: 'Shopping Bag Open',
    iconData: PhosphorIconsRegular.shoppingBagOpen,
  ),
  MemoToolbarCustomIconOption(
    key: 'shoppingCart',
    label: 'Shopping Cart',
    iconData: PhosphorIconsRegular.shoppingCart,
  ),
  MemoToolbarCustomIconOption(
    key: 'shoppingCartSimple',
    label: 'Shopping Cart Simple',
    iconData: PhosphorIconsRegular.shoppingCartSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'shovel',
    label: 'Shovel',
    iconData: PhosphorIconsRegular.shovel,
  ),
  MemoToolbarCustomIconOption(
    key: 'shower',
    label: 'Shower',
    iconData: PhosphorIconsRegular.shower,
  ),
  MemoToolbarCustomIconOption(
    key: 'shrimp',
    label: 'Shrimp',
    iconData: PhosphorIconsRegular.shrimp,
  ),
  MemoToolbarCustomIconOption(
    key: 'shuffle',
    label: 'Shuffle',
    iconData: PhosphorIconsRegular.shuffle,
  ),
  MemoToolbarCustomIconOption(
    key: 'shuffleAngular',
    label: 'Shuffle Angular',
    iconData: PhosphorIconsRegular.shuffleAngular,
  ),
  MemoToolbarCustomIconOption(
    key: 'shuffleSimple',
    label: 'Shuffle Simple',
    iconData: PhosphorIconsRegular.shuffleSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'sidebar',
    label: 'Sidebar',
    iconData: PhosphorIconsRegular.sidebar,
  ),
  MemoToolbarCustomIconOption(
    key: 'sidebarSimple',
    label: 'Sidebar Simple',
    iconData: PhosphorIconsRegular.sidebarSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'sigma',
    label: 'Sigma',
    iconData: PhosphorIconsRegular.sigma,
  ),
  MemoToolbarCustomIconOption(
    key: 'signIn',
    label: 'Sign In',
    iconData: PhosphorIconsRegular.signIn,
  ),
  MemoToolbarCustomIconOption(
    key: 'signOut',
    label: 'Sign Out',
    iconData: PhosphorIconsRegular.signOut,
  ),
  MemoToolbarCustomIconOption(
    key: 'signature',
    label: 'Signature',
    iconData: PhosphorIconsRegular.signature,
  ),
  MemoToolbarCustomIconOption(
    key: 'signpost',
    label: 'Signpost',
    iconData: PhosphorIconsRegular.signpost,
  ),
  MemoToolbarCustomIconOption(
    key: 'simCard',
    label: 'Sim Card',
    iconData: PhosphorIconsRegular.simCard,
  ),
  MemoToolbarCustomIconOption(
    key: 'siren',
    label: 'Siren',
    iconData: PhosphorIconsRegular.siren,
  ),
  MemoToolbarCustomIconOption(
    key: 'sketchLogo',
    label: 'Sketch Logo',
    iconData: PhosphorIconsRegular.sketchLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'skipBack',
    label: 'Skip Back',
    iconData: PhosphorIconsRegular.skipBack,
  ),
  MemoToolbarCustomIconOption(
    key: 'skipBackCircle',
    label: 'Skip Back Circle',
    iconData: PhosphorIconsRegular.skipBackCircle,
  ),
  MemoToolbarCustomIconOption(
    key: 'skipForward',
    label: 'Skip Forward',
    iconData: PhosphorIconsRegular.skipForward,
  ),
  MemoToolbarCustomIconOption(
    key: 'skipForwardCircle',
    label: 'Skip Forward Circle',
    iconData: PhosphorIconsRegular.skipForwardCircle,
  ),
  MemoToolbarCustomIconOption(
    key: 'skull',
    label: 'Skull',
    iconData: PhosphorIconsRegular.skull,
  ),
  MemoToolbarCustomIconOption(
    key: 'skypeLogo',
    label: 'Skype Logo',
    iconData: PhosphorIconsRegular.skypeLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'slackLogo',
    label: 'Slack Logo',
    iconData: PhosphorIconsRegular.slackLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'sliders',
    label: 'Sliders',
    iconData: PhosphorIconsRegular.sliders,
  ),
  MemoToolbarCustomIconOption(
    key: 'slidersHorizontal',
    label: 'Sliders Horizontal',
    iconData: PhosphorIconsRegular.slidersHorizontal,
  ),
  MemoToolbarCustomIconOption(
    key: 'slideshow',
    label: 'Slideshow',
    iconData: PhosphorIconsRegular.slideshow,
  ),
  MemoToolbarCustomIconOption(
    key: 'smiley',
    label: 'Smiley',
    iconData: PhosphorIconsRegular.smiley,
  ),
  MemoToolbarCustomIconOption(
    key: 'smileyAngry',
    label: 'Smiley Angry',
    iconData: PhosphorIconsRegular.smileyAngry,
  ),
  MemoToolbarCustomIconOption(
    key: 'smileyBlank',
    label: 'Smiley Blank',
    iconData: PhosphorIconsRegular.smileyBlank,
  ),
  MemoToolbarCustomIconOption(
    key: 'smileyMeh',
    label: 'Smiley Meh',
    iconData: PhosphorIconsRegular.smileyMeh,
  ),
  MemoToolbarCustomIconOption(
    key: 'smileyMelting',
    label: 'Smiley Melting',
    iconData: PhosphorIconsRegular.smileyMelting,
  ),
  MemoToolbarCustomIconOption(
    key: 'smileyNervous',
    label: 'Smiley Nervous',
    iconData: PhosphorIconsRegular.smileyNervous,
  ),
  MemoToolbarCustomIconOption(
    key: 'smileySad',
    label: 'Smiley Sad',
    iconData: PhosphorIconsRegular.smileySad,
  ),
  MemoToolbarCustomIconOption(
    key: 'smileySticker',
    label: 'Smiley Sticker',
    iconData: PhosphorIconsRegular.smileySticker,
  ),
  MemoToolbarCustomIconOption(
    key: 'smileyWink',
    label: 'Smiley Wink',
    iconData: PhosphorIconsRegular.smileyWink,
  ),
  MemoToolbarCustomIconOption(
    key: 'smileyXEyes',
    label: 'Smiley X Eyes',
    iconData: PhosphorIconsRegular.smileyXEyes,
  ),
  MemoToolbarCustomIconOption(
    key: 'snapchatLogo',
    label: 'Snapchat Logo',
    iconData: PhosphorIconsRegular.snapchatLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'sneaker',
    label: 'Sneaker',
    iconData: PhosphorIconsRegular.sneaker,
  ),
  MemoToolbarCustomIconOption(
    key: 'sneakerMove',
    label: 'Sneaker Move',
    iconData: PhosphorIconsRegular.sneakerMove,
  ),
  MemoToolbarCustomIconOption(
    key: 'snowflake',
    label: 'Snowflake',
    iconData: PhosphorIconsRegular.snowflake,
  ),
  MemoToolbarCustomIconOption(
    key: 'soccerBall',
    label: 'Soccer Ball',
    iconData: PhosphorIconsRegular.soccerBall,
  ),
  MemoToolbarCustomIconOption(
    key: 'sock',
    label: 'Sock',
    iconData: PhosphorIconsRegular.sock,
  ),
  MemoToolbarCustomIconOption(
    key: 'solarPanel',
    label: 'Solar Panel',
    iconData: PhosphorIconsRegular.solarPanel,
  ),
  MemoToolbarCustomIconOption(
    key: 'solarRoof',
    label: 'Solar Roof',
    iconData: PhosphorIconsRegular.solarRoof,
  ),
  MemoToolbarCustomIconOption(
    key: 'sortAscending',
    label: 'Sort Ascending',
    iconData: PhosphorIconsRegular.sortAscending,
  ),
  MemoToolbarCustomIconOption(
    key: 'sortDescending',
    label: 'Sort Descending',
    iconData: PhosphorIconsRegular.sortDescending,
  ),
  MemoToolbarCustomIconOption(
    key: 'soundcloudLogo',
    label: 'Soundcloud Logo',
    iconData: PhosphorIconsRegular.soundcloudLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'spade',
    label: 'Spade',
    iconData: PhosphorIconsRegular.spade,
  ),
  MemoToolbarCustomIconOption(
    key: 'sparkle',
    label: 'Sparkle',
    iconData: PhosphorIconsRegular.sparkle,
  ),
  MemoToolbarCustomIconOption(
    key: 'speakerHifi',
    label: 'Speaker Hifi',
    iconData: PhosphorIconsRegular.speakerHifi,
  ),
  MemoToolbarCustomIconOption(
    key: 'speakerHigh',
    label: 'Speaker High',
    iconData: PhosphorIconsRegular.speakerHigh,
  ),
  MemoToolbarCustomIconOption(
    key: 'speakerLow',
    label: 'Speaker Low',
    iconData: PhosphorIconsRegular.speakerLow,
  ),
  MemoToolbarCustomIconOption(
    key: 'speakerNone',
    label: 'Speaker None',
    iconData: PhosphorIconsRegular.speakerNone,
  ),
  MemoToolbarCustomIconOption(
    key: 'speakerSimpleHigh',
    label: 'Speaker Simple High',
    iconData: PhosphorIconsRegular.speakerSimpleHigh,
  ),
  MemoToolbarCustomIconOption(
    key: 'speakerSimpleLow',
    label: 'Speaker Simple Low',
    iconData: PhosphorIconsRegular.speakerSimpleLow,
  ),
  MemoToolbarCustomIconOption(
    key: 'speakerSimpleNone',
    label: 'Speaker Simple None',
    iconData: PhosphorIconsRegular.speakerSimpleNone,
  ),
  MemoToolbarCustomIconOption(
    key: 'speakerSimpleSlash',
    label: 'Speaker Simple Slash',
    iconData: PhosphorIconsRegular.speakerSimpleSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'speakerSimpleX',
    label: 'Speaker Simple X',
    iconData: PhosphorIconsRegular.speakerSimpleX,
  ),
  MemoToolbarCustomIconOption(
    key: 'speakerSlash',
    label: 'Speaker Slash',
    iconData: PhosphorIconsRegular.speakerSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'speakerX',
    label: 'Speaker X',
    iconData: PhosphorIconsRegular.speakerX,
  ),
  MemoToolbarCustomIconOption(
    key: 'speedometer',
    label: 'Speedometer',
    iconData: PhosphorIconsRegular.speedometer,
  ),
  MemoToolbarCustomIconOption(
    key: 'sphere',
    label: 'Sphere',
    iconData: PhosphorIconsRegular.sphere,
  ),
  MemoToolbarCustomIconOption(
    key: 'spinner',
    label: 'Spinner',
    iconData: PhosphorIconsRegular.spinner,
  ),
  MemoToolbarCustomIconOption(
    key: 'spinnerBall',
    label: 'Spinner Ball',
    iconData: PhosphorIconsRegular.spinnerBall,
  ),
  MemoToolbarCustomIconOption(
    key: 'spinnerGap',
    label: 'Spinner Gap',
    iconData: PhosphorIconsRegular.spinnerGap,
  ),
  MemoToolbarCustomIconOption(
    key: 'spiral',
    label: 'Spiral',
    iconData: PhosphorIconsRegular.spiral,
  ),
  MemoToolbarCustomIconOption(
    key: 'splitHorizontal',
    label: 'Split Horizontal',
    iconData: PhosphorIconsRegular.splitHorizontal,
  ),
  MemoToolbarCustomIconOption(
    key: 'splitVertical',
    label: 'Split Vertical',
    iconData: PhosphorIconsRegular.splitVertical,
  ),
  MemoToolbarCustomIconOption(
    key: 'spotifyLogo',
    label: 'Spotify Logo',
    iconData: PhosphorIconsRegular.spotifyLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'sprayBottle',
    label: 'Spray Bottle',
    iconData: PhosphorIconsRegular.sprayBottle,
  ),
  MemoToolbarCustomIconOption(
    key: 'square',
    label: 'Square',
    iconData: PhosphorIconsRegular.square,
  ),
  MemoToolbarCustomIconOption(
    key: 'squareHalf',
    label: 'Square Half',
    iconData: PhosphorIconsRegular.squareHalf,
  ),
  MemoToolbarCustomIconOption(
    key: 'squareHalfBottom',
    label: 'Square Half Bottom',
    iconData: PhosphorIconsRegular.squareHalfBottom,
  ),
  MemoToolbarCustomIconOption(
    key: 'squareLogo',
    label: 'Square Logo',
    iconData: PhosphorIconsRegular.squareLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'squareSplitHorizontal',
    label: 'Square Split Horizontal',
    iconData: PhosphorIconsRegular.squareSplitHorizontal,
  ),
  MemoToolbarCustomIconOption(
    key: 'squareSplitVertical',
    label: 'Square Split Vertical',
    iconData: PhosphorIconsRegular.squareSplitVertical,
  ),
  MemoToolbarCustomIconOption(
    key: 'squaresFour',
    label: 'Squares Four',
    iconData: PhosphorIconsRegular.squaresFour,
  ),
  MemoToolbarCustomIconOption(
    key: 'stack',
    label: 'Stack',
    iconData: PhosphorIconsRegular.stack,
  ),
  MemoToolbarCustomIconOption(
    key: 'stackMinus',
    label: 'Stack Minus',
    iconData: PhosphorIconsRegular.stackMinus,
  ),
  MemoToolbarCustomIconOption(
    key: 'stackOverflowLogo',
    label: 'Stack Overflow Logo',
    iconData: PhosphorIconsRegular.stackOverflowLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'stackPlus',
    label: 'Stack Plus',
    iconData: PhosphorIconsRegular.stackPlus,
  ),
  MemoToolbarCustomIconOption(
    key: 'stackSimple',
    label: 'Stack Simple',
    iconData: PhosphorIconsRegular.stackSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'stairs',
    label: 'Stairs',
    iconData: PhosphorIconsRegular.stairs,
  ),
  MemoToolbarCustomIconOption(
    key: 'stamp',
    label: 'Stamp',
    iconData: PhosphorIconsRegular.stamp,
  ),
  MemoToolbarCustomIconOption(
    key: 'standardDefinition',
    label: 'Standard Definition',
    iconData: PhosphorIconsRegular.standardDefinition,
  ),
  MemoToolbarCustomIconOption(
    key: 'star',
    label: 'Star',
    iconData: PhosphorIconsRegular.star,
  ),
  MemoToolbarCustomIconOption(
    key: 'starAndCrescent',
    label: 'Star And Crescent',
    iconData: PhosphorIconsRegular.starAndCrescent,
  ),
  MemoToolbarCustomIconOption(
    key: 'starFour',
    label: 'Star Four',
    iconData: PhosphorIconsRegular.starFour,
  ),
  MemoToolbarCustomIconOption(
    key: 'starHalf',
    label: 'Star Half',
    iconData: PhosphorIconsRegular.starHalf,
  ),
  MemoToolbarCustomIconOption(
    key: 'starOfDavid',
    label: 'Star Of David',
    iconData: PhosphorIconsRegular.starOfDavid,
  ),
  MemoToolbarCustomIconOption(
    key: 'steamLogo',
    label: 'Steam Logo',
    iconData: PhosphorIconsRegular.steamLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'steeringWheel',
    label: 'Steering Wheel',
    iconData: PhosphorIconsRegular.steeringWheel,
  ),
  MemoToolbarCustomIconOption(
    key: 'steps',
    label: 'Steps',
    iconData: PhosphorIconsRegular.steps,
  ),
  MemoToolbarCustomIconOption(
    key: 'stethoscope',
    label: 'Stethoscope',
    iconData: PhosphorIconsRegular.stethoscope,
  ),
  MemoToolbarCustomIconOption(
    key: 'sticker',
    label: 'Sticker',
    iconData: PhosphorIconsRegular.sticker,
  ),
  MemoToolbarCustomIconOption(
    key: 'stool',
    label: 'Stool',
    iconData: PhosphorIconsRegular.stool,
  ),
  MemoToolbarCustomIconOption(
    key: 'stop',
    label: 'Stop',
    iconData: PhosphorIconsRegular.stop,
  ),
  MemoToolbarCustomIconOption(
    key: 'stopCircle',
    label: 'Stop Circle',
    iconData: PhosphorIconsRegular.stopCircle,
  ),
  MemoToolbarCustomIconOption(
    key: 'storefront',
    label: 'Storefront',
    iconData: PhosphorIconsRegular.storefront,
  ),
  MemoToolbarCustomIconOption(
    key: 'strategy',
    label: 'Strategy',
    iconData: PhosphorIconsRegular.strategy,
  ),
  MemoToolbarCustomIconOption(
    key: 'stripeLogo',
    label: 'Stripe Logo',
    iconData: PhosphorIconsRegular.stripeLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'student',
    label: 'Student',
    iconData: PhosphorIconsRegular.student,
  ),
  MemoToolbarCustomIconOption(
    key: 'subsetOf',
    label: 'Subset Of',
    iconData: PhosphorIconsRegular.subsetOf,
  ),
  MemoToolbarCustomIconOption(
    key: 'subsetProperOf',
    label: 'Subset Proper Of',
    iconData: PhosphorIconsRegular.subsetProperOf,
  ),
  MemoToolbarCustomIconOption(
    key: 'subtitles',
    label: 'Subtitles',
    iconData: PhosphorIconsRegular.subtitles,
  ),
  MemoToolbarCustomIconOption(
    key: 'subtitlesSlash',
    label: 'Subtitles Slash',
    iconData: PhosphorIconsRegular.subtitlesSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'subtract',
    label: 'Subtract',
    iconData: PhosphorIconsRegular.subtract,
  ),
  MemoToolbarCustomIconOption(
    key: 'subtractSquare',
    label: 'Subtract Square',
    iconData: PhosphorIconsRegular.subtractSquare,
  ),
  MemoToolbarCustomIconOption(
    key: 'subway',
    label: 'Subway',
    iconData: PhosphorIconsRegular.subway,
  ),
  MemoToolbarCustomIconOption(
    key: 'suitcase',
    label: 'Suitcase',
    iconData: PhosphorIconsRegular.suitcase,
  ),
  MemoToolbarCustomIconOption(
    key: 'suitcaseRolling',
    label: 'Suitcase Rolling',
    iconData: PhosphorIconsRegular.suitcaseRolling,
  ),
  MemoToolbarCustomIconOption(
    key: 'suitcaseSimple',
    label: 'Suitcase Simple',
    iconData: PhosphorIconsRegular.suitcaseSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'sun',
    label: 'Sun',
    iconData: PhosphorIconsRegular.sun,
  ),
  MemoToolbarCustomIconOption(
    key: 'sunDim',
    label: 'Sun Dim',
    iconData: PhosphorIconsRegular.sunDim,
  ),
  MemoToolbarCustomIconOption(
    key: 'sunHorizon',
    label: 'Sun Horizon',
    iconData: PhosphorIconsRegular.sunHorizon,
  ),
  MemoToolbarCustomIconOption(
    key: 'sunglasses',
    label: 'Sunglasses',
    iconData: PhosphorIconsRegular.sunglasses,
  ),
  MemoToolbarCustomIconOption(
    key: 'supersetOf',
    label: 'Superset Of',
    iconData: PhosphorIconsRegular.supersetOf,
  ),
  MemoToolbarCustomIconOption(
    key: 'supersetProperOf',
    label: 'Superset Proper Of',
    iconData: PhosphorIconsRegular.supersetProperOf,
  ),
  MemoToolbarCustomIconOption(
    key: 'swap',
    label: 'Swap',
    iconData: PhosphorIconsRegular.swap,
  ),
  MemoToolbarCustomIconOption(
    key: 'swatches',
    label: 'Swatches',
    iconData: PhosphorIconsRegular.swatches,
  ),
  MemoToolbarCustomIconOption(
    key: 'swimmingPool',
    label: 'Swimming Pool',
    iconData: PhosphorIconsRegular.swimmingPool,
  ),
  MemoToolbarCustomIconOption(
    key: 'sword',
    label: 'Sword',
    iconData: PhosphorIconsRegular.sword,
  ),
  MemoToolbarCustomIconOption(
    key: 'synagogue',
    label: 'Synagogue',
    iconData: PhosphorIconsRegular.synagogue,
  ),
  MemoToolbarCustomIconOption(
    key: 'syringe',
    label: 'Syringe',
    iconData: PhosphorIconsRegular.syringe,
  ),
  MemoToolbarCustomIconOption(
    key: 'tShirt',
    label: 'T Shirt',
    iconData: PhosphorIconsRegular.tShirt,
  ),
  MemoToolbarCustomIconOption(
    key: 'table',
    label: 'Table',
    iconData: PhosphorIconsRegular.table,
  ),
  MemoToolbarCustomIconOption(
    key: 'tabs',
    label: 'Tabs',
    iconData: PhosphorIconsRegular.tabs,
  ),
  MemoToolbarCustomIconOption(
    key: 'tag',
    label: 'Tag',
    iconData: PhosphorIconsRegular.tag,
  ),
  MemoToolbarCustomIconOption(
    key: 'tagChevron',
    label: 'Tag Chevron',
    iconData: PhosphorIconsRegular.tagChevron,
  ),
  MemoToolbarCustomIconOption(
    key: 'tagSimple',
    label: 'Tag Simple',
    iconData: PhosphorIconsRegular.tagSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'target',
    label: 'Target',
    iconData: PhosphorIconsRegular.target,
  ),
  MemoToolbarCustomIconOption(
    key: 'taxi',
    label: 'Taxi',
    iconData: PhosphorIconsRegular.taxi,
  ),
  MemoToolbarCustomIconOption(
    key: 'teaBag',
    label: 'Tea Bag',
    iconData: PhosphorIconsRegular.teaBag,
  ),
  MemoToolbarCustomIconOption(
    key: 'telegramLogo',
    label: 'Telegram Logo',
    iconData: PhosphorIconsRegular.telegramLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'television',
    label: 'Television',
    iconData: PhosphorIconsRegular.television,
  ),
  MemoToolbarCustomIconOption(
    key: 'televisionSimple',
    label: 'Television Simple',
    iconData: PhosphorIconsRegular.televisionSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'tennisBall',
    label: 'Tennis Ball',
    iconData: PhosphorIconsRegular.tennisBall,
  ),
  MemoToolbarCustomIconOption(
    key: 'tent',
    label: 'Tent',
    iconData: PhosphorIconsRegular.tent,
  ),
  MemoToolbarCustomIconOption(
    key: 'terminal',
    label: 'Terminal',
    iconData: PhosphorIconsRegular.terminal,
  ),
  MemoToolbarCustomIconOption(
    key: 'terminalWindow',
    label: 'Terminal Window',
    iconData: PhosphorIconsRegular.terminalWindow,
  ),
  MemoToolbarCustomIconOption(
    key: 'testTube',
    label: 'Test Tube',
    iconData: PhosphorIconsRegular.testTube,
  ),
  MemoToolbarCustomIconOption(
    key: 'textAUnderline',
    label: 'Text A Underline',
    iconData: PhosphorIconsRegular.textAUnderline,
  ),
  MemoToolbarCustomIconOption(
    key: 'textAa',
    label: 'Text Aa',
    iconData: PhosphorIconsRegular.textAa,
  ),
  MemoToolbarCustomIconOption(
    key: 'textAlignCenter',
    label: 'Text Align Center',
    iconData: PhosphorIconsRegular.textAlignCenter,
  ),
  MemoToolbarCustomIconOption(
    key: 'textAlignJustify',
    label: 'Text Align Justify',
    iconData: PhosphorIconsRegular.textAlignJustify,
  ),
  MemoToolbarCustomIconOption(
    key: 'textAlignLeft',
    label: 'Text Align Left',
    iconData: PhosphorIconsRegular.textAlignLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'textAlignRight',
    label: 'Text Align Right',
    iconData: PhosphorIconsRegular.textAlignRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'textB',
    label: 'Text B',
    iconData: PhosphorIconsRegular.textB,
  ),
  MemoToolbarCustomIconOption(
    key: 'textColumns',
    label: 'Text Columns',
    iconData: PhosphorIconsRegular.textColumns,
  ),
  MemoToolbarCustomIconOption(
    key: 'textH',
    label: 'Text H',
    iconData: PhosphorIconsRegular.textH,
  ),
  MemoToolbarCustomIconOption(
    key: 'textHFive',
    label: 'Text H Five',
    iconData: PhosphorIconsRegular.textHFive,
  ),
  MemoToolbarCustomIconOption(
    key: 'textHFour',
    label: 'Text H Four',
    iconData: PhosphorIconsRegular.textHFour,
  ),
  MemoToolbarCustomIconOption(
    key: 'textHOne',
    label: 'Text H One',
    iconData: PhosphorIconsRegular.textHOne,
  ),
  MemoToolbarCustomIconOption(
    key: 'textHSix',
    label: 'Text H Six',
    iconData: PhosphorIconsRegular.textHSix,
  ),
  MemoToolbarCustomIconOption(
    key: 'textHThree',
    label: 'Text H Three',
    iconData: PhosphorIconsRegular.textHThree,
  ),
  MemoToolbarCustomIconOption(
    key: 'textHTwo',
    label: 'Text H Two',
    iconData: PhosphorIconsRegular.textHTwo,
  ),
  MemoToolbarCustomIconOption(
    key: 'textIndent',
    label: 'Text Indent',
    iconData: PhosphorIconsRegular.textIndent,
  ),
  MemoToolbarCustomIconOption(
    key: 'textItalic',
    label: 'Text Italic',
    iconData: PhosphorIconsRegular.textItalic,
  ),
  MemoToolbarCustomIconOption(
    key: 'textOutdent',
    label: 'Text Outdent',
    iconData: PhosphorIconsRegular.textOutdent,
  ),
  MemoToolbarCustomIconOption(
    key: 'textStrikethrough',
    label: 'Text Strikethrough',
    iconData: PhosphorIconsRegular.textStrikethrough,
  ),
  MemoToolbarCustomIconOption(
    key: 'textSubscript',
    label: 'Text Subscript',
    iconData: PhosphorIconsRegular.textSubscript,
  ),
  MemoToolbarCustomIconOption(
    key: 'textSuperscript',
    label: 'Text Superscript',
    iconData: PhosphorIconsRegular.textSuperscript,
  ),
  MemoToolbarCustomIconOption(
    key: 'textT',
    label: 'Text T',
    iconData: PhosphorIconsRegular.textT,
  ),
  MemoToolbarCustomIconOption(
    key: 'textTSlash',
    label: 'Text T Slash',
    iconData: PhosphorIconsRegular.textTSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'textUnderline',
    label: 'Text Underline',
    iconData: PhosphorIconsRegular.textUnderline,
  ),
  MemoToolbarCustomIconOption(
    key: 'textbox',
    label: 'Textbox',
    iconData: PhosphorIconsRegular.textbox,
  ),
  MemoToolbarCustomIconOption(
    key: 'thermometer',
    label: 'Thermometer',
    iconData: PhosphorIconsRegular.thermometer,
  ),
  MemoToolbarCustomIconOption(
    key: 'thermometerCold',
    label: 'Thermometer Cold',
    iconData: PhosphorIconsRegular.thermometerCold,
  ),
  MemoToolbarCustomIconOption(
    key: 'thermometerHot',
    label: 'Thermometer Hot',
    iconData: PhosphorIconsRegular.thermometerHot,
  ),
  MemoToolbarCustomIconOption(
    key: 'thermometerSimple',
    label: 'Thermometer Simple',
    iconData: PhosphorIconsRegular.thermometerSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'threadsLogo',
    label: 'Threads Logo',
    iconData: PhosphorIconsRegular.threadsLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'threeD',
    label: 'Three D',
    iconData: PhosphorIconsRegular.threeD,
  ),
  MemoToolbarCustomIconOption(
    key: 'thumbsDown',
    label: 'Thumbs Down',
    iconData: PhosphorIconsRegular.thumbsDown,
  ),
  MemoToolbarCustomIconOption(
    key: 'thumbsUp',
    label: 'Thumbs Up',
    iconData: PhosphorIconsRegular.thumbsUp,
  ),
  MemoToolbarCustomIconOption(
    key: 'ticket',
    label: 'Ticket',
    iconData: PhosphorIconsRegular.ticket,
  ),
  MemoToolbarCustomIconOption(
    key: 'tidalLogo',
    label: 'Tidal Logo',
    iconData: PhosphorIconsRegular.tidalLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'tiktokLogo',
    label: 'Tiktok Logo',
    iconData: PhosphorIconsRegular.tiktokLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'tilde',
    label: 'Tilde',
    iconData: PhosphorIconsRegular.tilde,
  ),
  MemoToolbarCustomIconOption(
    key: 'timer',
    label: 'Timer',
    iconData: PhosphorIconsRegular.timer,
  ),
  MemoToolbarCustomIconOption(
    key: 'tipJar',
    label: 'Tip Jar',
    iconData: PhosphorIconsRegular.tipJar,
  ),
  MemoToolbarCustomIconOption(
    key: 'tipi',
    label: 'Tipi',
    iconData: PhosphorIconsRegular.tipi,
  ),
  MemoToolbarCustomIconOption(
    key: 'tire',
    label: 'Tire',
    iconData: PhosphorIconsRegular.tire,
  ),
  MemoToolbarCustomIconOption(
    key: 'toggleLeft',
    label: 'Toggle Left',
    iconData: PhosphorIconsRegular.toggleLeft,
  ),
  MemoToolbarCustomIconOption(
    key: 'toggleRight',
    label: 'Toggle Right',
    iconData: PhosphorIconsRegular.toggleRight,
  ),
  MemoToolbarCustomIconOption(
    key: 'toilet',
    label: 'Toilet',
    iconData: PhosphorIconsRegular.toilet,
  ),
  MemoToolbarCustomIconOption(
    key: 'toiletPaper',
    label: 'Toilet Paper',
    iconData: PhosphorIconsRegular.toiletPaper,
  ),
  MemoToolbarCustomIconOption(
    key: 'toolbox',
    label: 'Toolbox',
    iconData: PhosphorIconsRegular.toolbox,
  ),
  MemoToolbarCustomIconOption(
    key: 'tooth',
    label: 'Tooth',
    iconData: PhosphorIconsRegular.tooth,
  ),
  MemoToolbarCustomIconOption(
    key: 'tornado',
    label: 'Tornado',
    iconData: PhosphorIconsRegular.tornado,
  ),
  MemoToolbarCustomIconOption(
    key: 'tote',
    label: 'Tote',
    iconData: PhosphorIconsRegular.tote,
  ),
  MemoToolbarCustomIconOption(
    key: 'toteSimple',
    label: 'Tote Simple',
    iconData: PhosphorIconsRegular.toteSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'towel',
    label: 'Towel',
    iconData: PhosphorIconsRegular.towel,
  ),
  MemoToolbarCustomIconOption(
    key: 'tractor',
    label: 'Tractor',
    iconData: PhosphorIconsRegular.tractor,
  ),
  MemoToolbarCustomIconOption(
    key: 'trademark',
    label: 'Trademark',
    iconData: PhosphorIconsRegular.trademark,
  ),
  MemoToolbarCustomIconOption(
    key: 'trademarkRegistered',
    label: 'Trademark Registered',
    iconData: PhosphorIconsRegular.trademarkRegistered,
  ),
  MemoToolbarCustomIconOption(
    key: 'trafficCone',
    label: 'Traffic Cone',
    iconData: PhosphorIconsRegular.trafficCone,
  ),
  MemoToolbarCustomIconOption(
    key: 'trafficSign',
    label: 'Traffic Sign',
    iconData: PhosphorIconsRegular.trafficSign,
  ),
  MemoToolbarCustomIconOption(
    key: 'trafficSignal',
    label: 'Traffic Signal',
    iconData: PhosphorIconsRegular.trafficSignal,
  ),
  MemoToolbarCustomIconOption(
    key: 'train',
    label: 'Train',
    iconData: PhosphorIconsRegular.train,
  ),
  MemoToolbarCustomIconOption(
    key: 'trainRegional',
    label: 'Train Regional',
    iconData: PhosphorIconsRegular.trainRegional,
  ),
  MemoToolbarCustomIconOption(
    key: 'trainSimple',
    label: 'Train Simple',
    iconData: PhosphorIconsRegular.trainSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'tram',
    label: 'Tram',
    iconData: PhosphorIconsRegular.tram,
  ),
  MemoToolbarCustomIconOption(
    key: 'translate',
    label: 'Translate',
    iconData: PhosphorIconsRegular.translate,
  ),
  MemoToolbarCustomIconOption(
    key: 'trash',
    label: 'Trash',
    iconData: PhosphorIconsRegular.trash,
  ),
  MemoToolbarCustomIconOption(
    key: 'trashSimple',
    label: 'Trash Simple',
    iconData: PhosphorIconsRegular.trashSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'tray',
    label: 'Tray',
    iconData: PhosphorIconsRegular.tray,
  ),
  MemoToolbarCustomIconOption(
    key: 'trayArrowDown',
    label: 'Tray Arrow Down',
    iconData: PhosphorIconsRegular.trayArrowDown,
  ),
  MemoToolbarCustomIconOption(
    key: 'trayArrowUp',
    label: 'Tray Arrow Up',
    iconData: PhosphorIconsRegular.trayArrowUp,
  ),
  MemoToolbarCustomIconOption(
    key: 'treasureChest',
    label: 'Treasure Chest',
    iconData: PhosphorIconsRegular.treasureChest,
  ),
  MemoToolbarCustomIconOption(
    key: 'tree',
    label: 'Tree',
    iconData: PhosphorIconsRegular.tree,
  ),
  MemoToolbarCustomIconOption(
    key: 'treeEvergreen',
    label: 'Tree Evergreen',
    iconData: PhosphorIconsRegular.treeEvergreen,
  ),
  MemoToolbarCustomIconOption(
    key: 'treePalm',
    label: 'Tree Palm',
    iconData: PhosphorIconsRegular.treePalm,
  ),
  MemoToolbarCustomIconOption(
    key: 'treeStructure',
    label: 'Tree Structure',
    iconData: PhosphorIconsRegular.treeStructure,
  ),
  MemoToolbarCustomIconOption(
    key: 'treeView',
    label: 'Tree View',
    iconData: PhosphorIconsRegular.treeView,
  ),
  MemoToolbarCustomIconOption(
    key: 'trendDown',
    label: 'Trend Down',
    iconData: PhosphorIconsRegular.trendDown,
  ),
  MemoToolbarCustomIconOption(
    key: 'trendUp',
    label: 'Trend Up',
    iconData: PhosphorIconsRegular.trendUp,
  ),
  MemoToolbarCustomIconOption(
    key: 'triangle',
    label: 'Triangle',
    iconData: PhosphorIconsRegular.triangle,
  ),
  MemoToolbarCustomIconOption(
    key: 'triangleDashed',
    label: 'Triangle Dashed',
    iconData: PhosphorIconsRegular.triangleDashed,
  ),
  MemoToolbarCustomIconOption(
    key: 'trolley',
    label: 'Trolley',
    iconData: PhosphorIconsRegular.trolley,
  ),
  MemoToolbarCustomIconOption(
    key: 'trolleySuitcase',
    label: 'Trolley Suitcase',
    iconData: PhosphorIconsRegular.trolleySuitcase,
  ),
  MemoToolbarCustomIconOption(
    key: 'trophy',
    label: 'Trophy',
    iconData: PhosphorIconsRegular.trophy,
  ),
  MemoToolbarCustomIconOption(
    key: 'truck',
    label: 'Truck',
    iconData: PhosphorIconsRegular.truck,
  ),
  MemoToolbarCustomIconOption(
    key: 'truckTrailer',
    label: 'Truck Trailer',
    iconData: PhosphorIconsRegular.truckTrailer,
  ),
  MemoToolbarCustomIconOption(
    key: 'tumblrLogo',
    label: 'Tumblr Logo',
    iconData: PhosphorIconsRegular.tumblrLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'twitchLogo',
    label: 'Twitch Logo',
    iconData: PhosphorIconsRegular.twitchLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'twitterLogo',
    label: 'Twitter Logo',
    iconData: PhosphorIconsRegular.twitterLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'umbrella',
    label: 'Umbrella',
    iconData: PhosphorIconsRegular.umbrella,
  ),
  MemoToolbarCustomIconOption(
    key: 'umbrellaSimple',
    label: 'Umbrella Simple',
    iconData: PhosphorIconsRegular.umbrellaSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'union',
    label: 'Union',
    iconData: PhosphorIconsRegular.union,
  ),
  MemoToolbarCustomIconOption(
    key: 'unite',
    label: 'Unite',
    iconData: PhosphorIconsRegular.unite,
  ),
  MemoToolbarCustomIconOption(
    key: 'uniteSquare',
    label: 'Unite Square',
    iconData: PhosphorIconsRegular.uniteSquare,
  ),
  MemoToolbarCustomIconOption(
    key: 'upload',
    label: 'Upload',
    iconData: PhosphorIconsRegular.upload,
  ),
  MemoToolbarCustomIconOption(
    key: 'uploadSimple',
    label: 'Upload Simple',
    iconData: PhosphorIconsRegular.uploadSimple,
  ),
  MemoToolbarCustomIconOption(
    key: 'usb',
    label: 'Usb',
    iconData: PhosphorIconsRegular.usb,
  ),
  MemoToolbarCustomIconOption(
    key: 'user',
    label: 'User',
    iconData: PhosphorIconsRegular.user,
  ),
  MemoToolbarCustomIconOption(
    key: 'userCheck',
    label: 'User Check',
    iconData: PhosphorIconsRegular.userCheck,
  ),
  MemoToolbarCustomIconOption(
    key: 'userCircle',
    label: 'User Circle',
    iconData: PhosphorIconsRegular.userCircle,
  ),
  MemoToolbarCustomIconOption(
    key: 'userCircleCheck',
    label: 'User Circle Check',
    iconData: PhosphorIconsRegular.userCircleCheck,
  ),
  MemoToolbarCustomIconOption(
    key: 'userCircleDashed',
    label: 'User Circle Dashed',
    iconData: PhosphorIconsRegular.userCircleDashed,
  ),
  MemoToolbarCustomIconOption(
    key: 'userCircleGear',
    label: 'User Circle Gear',
    iconData: PhosphorIconsRegular.userCircleGear,
  ),
  MemoToolbarCustomIconOption(
    key: 'userCircleMinus',
    label: 'User Circle Minus',
    iconData: PhosphorIconsRegular.userCircleMinus,
  ),
  MemoToolbarCustomIconOption(
    key: 'userCirclePlus',
    label: 'User Circle Plus',
    iconData: PhosphorIconsRegular.userCirclePlus,
  ),
  MemoToolbarCustomIconOption(
    key: 'userFocus',
    label: 'User Focus',
    iconData: PhosphorIconsRegular.userFocus,
  ),
  MemoToolbarCustomIconOption(
    key: 'userGear',
    label: 'User Gear',
    iconData: PhosphorIconsRegular.userGear,
  ),
  MemoToolbarCustomIconOption(
    key: 'userList',
    label: 'User List',
    iconData: PhosphorIconsRegular.userList,
  ),
  MemoToolbarCustomIconOption(
    key: 'userMinus',
    label: 'User Minus',
    iconData: PhosphorIconsRegular.userMinus,
  ),
  MemoToolbarCustomIconOption(
    key: 'userPlus',
    label: 'User Plus',
    iconData: PhosphorIconsRegular.userPlus,
  ),
  MemoToolbarCustomIconOption(
    key: 'userRectangle',
    label: 'User Rectangle',
    iconData: PhosphorIconsRegular.userRectangle,
  ),
  MemoToolbarCustomIconOption(
    key: 'userSound',
    label: 'User Sound',
    iconData: PhosphorIconsRegular.userSound,
  ),
  MemoToolbarCustomIconOption(
    key: 'userSquare',
    label: 'User Square',
    iconData: PhosphorIconsRegular.userSquare,
  ),
  MemoToolbarCustomIconOption(
    key: 'userSwitch',
    label: 'User Switch',
    iconData: PhosphorIconsRegular.userSwitch,
  ),
  MemoToolbarCustomIconOption(
    key: 'users',
    label: 'Users',
    iconData: PhosphorIconsRegular.users,
  ),
  MemoToolbarCustomIconOption(
    key: 'usersFour',
    label: 'Users Four',
    iconData: PhosphorIconsRegular.usersFour,
  ),
  MemoToolbarCustomIconOption(
    key: 'usersThree',
    label: 'Users Three',
    iconData: PhosphorIconsRegular.usersThree,
  ),
  MemoToolbarCustomIconOption(
    key: 'van',
    label: 'Van',
    iconData: PhosphorIconsRegular.van,
  ),
  MemoToolbarCustomIconOption(
    key: 'vault',
    label: 'Vault',
    iconData: PhosphorIconsRegular.vault,
  ),
  MemoToolbarCustomIconOption(
    key: 'vectorThree',
    label: 'Vector Three',
    iconData: PhosphorIconsRegular.vectorThree,
  ),
  MemoToolbarCustomIconOption(
    key: 'vectorTwo',
    label: 'Vector Two',
    iconData: PhosphorIconsRegular.vectorTwo,
  ),
  MemoToolbarCustomIconOption(
    key: 'vibrate',
    label: 'Vibrate',
    iconData: PhosphorIconsRegular.vibrate,
  ),
  MemoToolbarCustomIconOption(
    key: 'video',
    label: 'Video',
    iconData: PhosphorIconsRegular.video,
  ),
  MemoToolbarCustomIconOption(
    key: 'videoCamera',
    label: 'Video Camera',
    iconData: PhosphorIconsRegular.videoCamera,
  ),
  MemoToolbarCustomIconOption(
    key: 'videoCameraSlash',
    label: 'Video Camera Slash',
    iconData: PhosphorIconsRegular.videoCameraSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'videoConference',
    label: 'Video Conference',
    iconData: PhosphorIconsRegular.videoConference,
  ),
  MemoToolbarCustomIconOption(
    key: 'vignette',
    label: 'Vignette',
    iconData: PhosphorIconsRegular.vignette,
  ),
  MemoToolbarCustomIconOption(
    key: 'vinylRecord',
    label: 'Vinyl Record',
    iconData: PhosphorIconsRegular.vinylRecord,
  ),
  MemoToolbarCustomIconOption(
    key: 'virtualReality',
    label: 'Virtual Reality',
    iconData: PhosphorIconsRegular.virtualReality,
  ),
  MemoToolbarCustomIconOption(
    key: 'virus',
    label: 'Virus',
    iconData: PhosphorIconsRegular.virus,
  ),
  MemoToolbarCustomIconOption(
    key: 'visor',
    label: 'Visor',
    iconData: PhosphorIconsRegular.visor,
  ),
  MemoToolbarCustomIconOption(
    key: 'voicemail',
    label: 'Voicemail',
    iconData: PhosphorIconsRegular.voicemail,
  ),
  MemoToolbarCustomIconOption(
    key: 'volleyball',
    label: 'Volleyball',
    iconData: PhosphorIconsRegular.volleyball,
  ),
  MemoToolbarCustomIconOption(
    key: 'wall',
    label: 'Wall',
    iconData: PhosphorIconsRegular.wall,
  ),
  MemoToolbarCustomIconOption(
    key: 'wallet',
    label: 'Wallet',
    iconData: PhosphorIconsRegular.wallet,
  ),
  MemoToolbarCustomIconOption(
    key: 'warehouse',
    label: 'Warehouse',
    iconData: PhosphorIconsRegular.warehouse,
  ),
  MemoToolbarCustomIconOption(
    key: 'warning',
    label: 'Warning',
    iconData: PhosphorIconsRegular.warning,
  ),
  MemoToolbarCustomIconOption(
    key: 'warningCircle',
    label: 'Warning Circle',
    iconData: PhosphorIconsRegular.warningCircle,
  ),
  MemoToolbarCustomIconOption(
    key: 'warningDiamond',
    label: 'Warning Diamond',
    iconData: PhosphorIconsRegular.warningDiamond,
  ),
  MemoToolbarCustomIconOption(
    key: 'warningOctagon',
    label: 'Warning Octagon',
    iconData: PhosphorIconsRegular.warningOctagon,
  ),
  MemoToolbarCustomIconOption(
    key: 'washingMachine',
    label: 'Washing Machine',
    iconData: PhosphorIconsRegular.washingMachine,
  ),
  MemoToolbarCustomIconOption(
    key: 'watch',
    label: 'Watch',
    iconData: PhosphorIconsRegular.watch,
  ),
  MemoToolbarCustomIconOption(
    key: 'waveSawtooth',
    label: 'Wave Sawtooth',
    iconData: PhosphorIconsRegular.waveSawtooth,
  ),
  MemoToolbarCustomIconOption(
    key: 'waveSine',
    label: 'Wave Sine',
    iconData: PhosphorIconsRegular.waveSine,
  ),
  MemoToolbarCustomIconOption(
    key: 'waveSquare',
    label: 'Wave Square',
    iconData: PhosphorIconsRegular.waveSquare,
  ),
  MemoToolbarCustomIconOption(
    key: 'waveTriangle',
    label: 'Wave Triangle',
    iconData: PhosphorIconsRegular.waveTriangle,
  ),
  MemoToolbarCustomIconOption(
    key: 'waveform',
    label: 'Waveform',
    iconData: PhosphorIconsRegular.waveform,
  ),
  MemoToolbarCustomIconOption(
    key: 'waveformSlash',
    label: 'Waveform Slash',
    iconData: PhosphorIconsRegular.waveformSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'waves',
    label: 'Waves',
    iconData: PhosphorIconsRegular.waves,
  ),
  MemoToolbarCustomIconOption(
    key: 'webcam',
    label: 'Webcam',
    iconData: PhosphorIconsRegular.webcam,
  ),
  MemoToolbarCustomIconOption(
    key: 'webcamSlash',
    label: 'Webcam Slash',
    iconData: PhosphorIconsRegular.webcamSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'webhooksLogo',
    label: 'Webhooks Logo',
    iconData: PhosphorIconsRegular.webhooksLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'wechatLogo',
    label: 'Wechat Logo',
    iconData: PhosphorIconsRegular.wechatLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'whatsappLogo',
    label: 'Whatsapp Logo',
    iconData: PhosphorIconsRegular.whatsappLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'wheelchair',
    label: 'Wheelchair',
    iconData: PhosphorIconsRegular.wheelchair,
  ),
  MemoToolbarCustomIconOption(
    key: 'wheelchairMotion',
    label: 'Wheelchair Motion',
    iconData: PhosphorIconsRegular.wheelchairMotion,
  ),
  MemoToolbarCustomIconOption(
    key: 'wifiHigh',
    label: 'Wifi High',
    iconData: PhosphorIconsRegular.wifiHigh,
  ),
  MemoToolbarCustomIconOption(
    key: 'wifiLow',
    label: 'Wifi Low',
    iconData: PhosphorIconsRegular.wifiLow,
  ),
  MemoToolbarCustomIconOption(
    key: 'wifiMedium',
    label: 'Wifi Medium',
    iconData: PhosphorIconsRegular.wifiMedium,
  ),
  MemoToolbarCustomIconOption(
    key: 'wifiNone',
    label: 'Wifi None',
    iconData: PhosphorIconsRegular.wifiNone,
  ),
  MemoToolbarCustomIconOption(
    key: 'wifiSlash',
    label: 'Wifi Slash',
    iconData: PhosphorIconsRegular.wifiSlash,
  ),
  MemoToolbarCustomIconOption(
    key: 'wifiX',
    label: 'Wifi X',
    iconData: PhosphorIconsRegular.wifiX,
  ),
  MemoToolbarCustomIconOption(
    key: 'wind',
    label: 'Wind',
    iconData: PhosphorIconsRegular.wind,
  ),
  MemoToolbarCustomIconOption(
    key: 'windmill',
    label: 'Windmill',
    iconData: PhosphorIconsRegular.windmill,
  ),
  MemoToolbarCustomIconOption(
    key: 'windowsLogo',
    label: 'Windows Logo',
    iconData: PhosphorIconsRegular.windowsLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'wine',
    label: 'Wine',
    iconData: PhosphorIconsRegular.wine,
  ),
  MemoToolbarCustomIconOption(
    key: 'wrench',
    label: 'Wrench',
    iconData: PhosphorIconsRegular.wrench,
  ),
  MemoToolbarCustomIconOption(
    key: 'x',
    label: 'X',
    iconData: PhosphorIconsRegular.x,
  ),
  MemoToolbarCustomIconOption(
    key: 'xCircle',
    label: 'X Circle',
    iconData: PhosphorIconsRegular.xCircle,
  ),
  MemoToolbarCustomIconOption(
    key: 'xLogo',
    label: 'X Logo',
    iconData: PhosphorIconsRegular.xLogo,
  ),
  MemoToolbarCustomIconOption(
    key: 'xSquare',
    label: 'X Square',
    iconData: PhosphorIconsRegular.xSquare,
  ),
  MemoToolbarCustomIconOption(
    key: 'yarn',
    label: 'Yarn',
    iconData: PhosphorIconsRegular.yarn,
  ),
  MemoToolbarCustomIconOption(
    key: 'yinYang',
    label: 'Yin Yang',
    iconData: PhosphorIconsRegular.yinYang,
  ),
  MemoToolbarCustomIconOption(
    key: 'youtubeLogo',
    label: 'Youtube Logo',
    iconData: PhosphorIconsRegular.youtubeLogo,
  ),
];

final kMemoToolbarCustomIconOptionMap = <String, MemoToolbarCustomIconOption>{
  for (final option in kMemoToolbarCustomIconOptions) option.key: option,
};

MemoToolbarCustomIconOption resolveMemoToolbarCustomIconOption(String? key) {
  return kMemoToolbarCustomIconOptionMap[key] ??
      kMemoToolbarCustomIconOptionMap[kMemoToolbarDefaultCustomIconKey]!;
}

IconData resolveMemoToolbarCustomIcon(String? key) {
  return resolveMemoToolbarCustomIconOption(key).iconData;
}
