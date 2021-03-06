/*
 * Copyright (C) 2013-2014 Canonical Ltd
 *
 * This file is part of Ubuntu Calendar App
 *
 * Ubuntu Calendar App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * Ubuntu Calendar App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick 2.3
import Ubuntu.Components 1.1
import HebrewCalendar 1.0
Item{
    id: root
    objectName: "MonthComponent"

    property bool isCurrentItem;

    property var currentMonth;
    property var isYearView;

    property string dayLabelFontSize: "medium"
    property string dateLabelFontSize: "large"
    property string monthLabelFontSize: "x-large"
    property string yearLabelFontSize: "large"

    property alias dayLabelDelegate : dayLabelRepeater.delegate
    property alias dateLabelDelegate : dateLabelRepeater.delegate

    signal monthSelected(var date);
    signal dateSelected(var date)

    HDate{
        id:hebrewDate
    }
//    Settings{
//        id:settings
//    }
    QtObject{
        id: intern

       property int curMonthDate: hebrewDate.getDay(currentMonth)
        property int curMonth: hebrewDate.getMonth(currentMonth)
        property int curMonthYear: hebrewDate.getYear(currentMonth)

        property var today:hebrewDate.today()
        property int todayDate: hebrewDate.getDay(today)
        property int todayMonth: hebrewDate.getMonth(today)
        property int todayYear: hebrewDate.getYear(today)

        property var monthStart: hebrewDate.weekStartMonth( currentMonth)
        property int monthStartDate: hebrewDate.getDay(monthStart)
        property int monthStartMonth: hebrewDate.getMonth(monthStart)
        property int monthStartYear: hebrewDate.getYear(monthStart)

        property int daysInStartMonth: hebrewDate.daysInMonth(monthStart)
        property int daysInCurMonth:  hebrewDate.daysInMonth(currentMonth)

        //check if current month is start month
        property bool isCurMonthStartMonth: curMonthDate === monthStartDate
                                            && curMonth === monthStartMonth
                                            && curMonthYear === monthStartYear

        //check current month is same as today's month
        property bool isCurMonthTodayMonth: todayYear === curMonthYear && todayMonth == curMonth
        //offset from current month's first date to start date of current month
        property int offset: isCurMonthStartMonth ? -1 : (daysInStartMonth - monthStartDate)

        property int dateFontSize: FontUtils.sizeToPixels(root.dateLabelFontSize)
        property int dayFontSize: FontUtils.sizeToPixels(root.dayLabelFontSize)


    }

    Column{
        id: column

        anchors {
            fill: parent
            topMargin: units.gu(1.5)
            bottomMargin: units.gu(1)
        }

        spacing: units.gu(1.5)

        Loader {
            width: parent.width
            height: isYearView ? FontUtils.sizeToPixels(root.monthLabelFontSize) : 0;
            sourceComponent: isYearView ? headerComp : undefined

            Component{
                id: headerComp
                ViewHeader{
                    id: monthHeader
                    anchors.fill: parent
                    month: intern.curMonth
                    year: intern.curMonthYear

                    monthLabelFontSize: root.monthLabelFontSize
                    yearLabelFontSize: root.yearLabelFontSize
                }

            }
        }

        Item {
            width: parent.width
            height: dayLabelRow.height + units.gu(1)

            Row{
                id: dayLabelRow

                property int dayWidth: width / 7;

                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

                Repeater{
                    id: dayLabelRepeater
                    model:7
                    delegate: dafaultDayLabelComponent
                }
            }
        }

        Grid{
            id: monthGrid
            objectName: "monthGrid"

            width: parent.width
            height: parent.height - monthGrid.y

            property int dayWidth: width / 7 /*cols*/;
            property int dayHeight: height / 6/*rows*/;

            rows: 6
            columns: 7
            Repeater{
                id: dateLabelRepeater
                model: 42 //monthGrid.rows * monthGrid.columns
                delegate: defaultDateLabelComponent
            }
        }
    }

    Component{
        id: defaultDateLabelComponent
        MonthComponentDateDelegate{
            date: {
                //try to find date from index and month's first week's first date
                var temp = intern.daysInStartMonth - intern.offset + index
                var c = 0;
                //date exceeds days in startMonth,
                //this means previous month is over and we are now in current month
                //to get actual date we need to remove number of days in startMonth
                if( temp > intern.daysInStartMonth ) {
                    temp = temp - intern.daysInStartMonth
                    //date exceeds days in current month
                    // this means date is from next month
                    //to get actual date we need to remove number of days in current month
                   c=1;
                    if( temp > intern.daysInCurMonth ) {
                        temp = temp - intern.daysInCurMonth
                        c=2;
                    }
                }
                var gd =0;
                if(c===0){
                     gd = hebrewDate.getGDay(hebrewDate.setHebDate(intern.monthStartYear,intern.monthStartMonth,temp));
                }else if(c===1){
                    gd = hebrewDate.getGDay(hebrewDate.setHebDate(intern.curMonthYear,intern.curMonth,temp));
                }else if (c===2){
                    var temp_d = hebrewDate.addMonths (hebrewDate.setHebDate(intern.curMonthYear,intern.curMonth,temp),1);
                    gd = hebrewDate.getGDay(hebrewDate.setHebDate(hebrewDate.getYear(temp_d),hebrewDate.getMonth(temp_d),temp));
                }
                return [temp,gd];
            }
            isHoliday:{
                var h = hebrewDate.setHebDate(intern.curMonthYear,intern.curMonth,date[0])
                var a = hebrewDate.isDateHoliday(h,settings.diaspora)
                return  a
            }

            isCurrentMonth: {
                //remove offset from index
                //if index falls in 1 to no of days in current month
                //then date is inside current month
                var temp = index - intern.offset
                return (temp >= 1 && temp <= intern.daysInCurMonth)
            }

            isToday: intern.todayDate == date[0] && intern.isCurMonthTodayMonth

            width: parent.dayWidth
            height: parent.dayHeight
            fontSize: intern.dateFontSize
        }
    }

    Component{
        id: dafaultDayLabelComponent

        Label{
            id: weekDay
            width: parent.dayWidth
            property var day : Qt.locale(Qt.locale().name).standaloneDayName(( Qt.locale().firstDayOfWeek + index), Locale.ShortFormat);
            text: isYearView ? Qt.locale(Qt.locale().name).standaloneDayName(( Qt.locale().firstDayOfWeek + index), Locale.NarrowFormat) : day
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: intern.dayFontSize
            font.bold: true
            color: "black"

        }
    }
}
