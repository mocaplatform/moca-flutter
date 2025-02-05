#!/bin/bash

#
#  dpublish.dart
#
#  Publishing script for Moca Flutter Plugin
#
#  This module is part of Moca platform.
#
#  Copyright (c) 2024 Moca Technologies.
#  All rights reserved.
#
#  All rights to this software by Moca Technologies are owned by 
#  Moca Technologies and only limited rights are provided by the 
# licensing or contract under which this software is provided.
#
#  Any use of the software for any commercial purpose without
#  the written permission of Moca Technologies is prohibited.
#  You may not alter, modify, or in any way change the appearance
#  and copyright notices on the software. You may not reverse compile
#  the software or publish any protected intellectual property embedded
#  in the software. You may not distribute, sell or make copies of
#  the software available to any entities without the explicit written
#  permission of Moca Technologies.
#

flutter clean
flutter pub get
flutter pub publish --dry-run

# final publish if all checks passed
flutter pub publish