//==============================================
//  courtesy accidentals v0.2
//
//  Copyright (C)2012-2015 Jörn Eichler (heuchi) 
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//==============================================

import QtQuick 2.2
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.3
import QtQuick.Dialogs 1.2
import MuseScore 1.0

MuseScore {
      version: "0.2"
      description: "This plugin adds courtesy accidentals"
      menuPath: "Plugins.Accidentals.Configure Courtesy Accidentals"

      // configuration
      property bool useBracket: false

      property var typeNextMeasure:  1
      property var typeNumMeasures:  2
      property var typeEvent:        3
      property var typeDodecaphonic: 4

      property var eventFullRest:      1
      property var eventDoubleBar:     2
      property var eventRehearsalMark: 4
      property var eventEndScore:      8 // we don't really need this, but...

      property var operationMode;
      property var numMeasures;
      property var eventTypes;

      // Error dialog

      MessageDialog {
            id: errorDialog
            visible: false
            icon: StandardIcon.Warning
      }

      // Dialog window

      Dialog {
            id: configDialog
            visible: true

            contentItem: Rectangle {
                  id: rect1
                  implicitWidth: 290
                  implicitHeight: 290
                  color: "lightgrey"
                  
                  ColumnLayout {
                        id: col1

                        ExclusiveGroup {id: typeGroup}

                        Label {
                             text: "Add courtesy accidentals for"
                        }

                        RowLayout {
                              Rectangle { // for indentation
                                    width: 10
                              }

                              ColumnLayout {

                                    Rectangle {height: 2}
                                    RadioButton {
                                          id: optNextMeasure
                                          text: "notes up to the next measure"
                                          checked: true
                                          exclusiveGroup: typeGroup
                                    }

                                    Rectangle {height: 2}
                                    RowLayout {
                                          RadioButton {
                                                id: optNumMeasures
                                                text: "notes up to the next"
                                                exclusiveGroup: typeGroup
                                          }

                                          SpinBox {
                                                id: valNumMeasures
                                                implicitWidth: 45
                                                horizontalAlignment: Qt.AlignRight
                                                decimals: 0
                                                minimumValue: 2
                                                maximumValue: 99
                                          }

                                          Label {
                                                text: "measures"
                                          }
                                    }
                        
                                    RowLayout {
                                          RadioButton {
                                                Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                                                id: optEvent
                                                text: "notes up to the"
                                                exclusiveGroup: typeGroup
                                          }

                                          ColumnLayout {
                                                CheckBox {
                                                      id: optFullRest
                                                      text: "next full measure rest"
                                                      checked: true
                                                }
                                                CheckBox {
                                                      id: optDoubleBar
                                                      text: "next double bar line"
                                                      checked: true
                                                }
                                                CheckBox {
                                                      id: optRehearsalMark
                                                      text: "next rehearsal mark"
                                                      checked: false
                                                }
                                                CheckBox {
                                                      id: optEndScore
                                                      text: "end of the score"
                                                      checked: true
                                                }
                                          }
                                    }

                                    Rectangle {height: 2}
                                    RadioButton {
                                          id: optDodecaphonic
                                          text:"all notes (dodecaphonic style)"
                                          exclusiveGroup: typeGroup
                                    }
                              }
                        }

                        Rectangle {height: 4}

                        // Parenthesis option
                        CheckBox {
                              id: optUseBracket
                              text: "Put accidentals in parenthesis"
                              checked: false
                              Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        }
                  }
                  // The buttons

                  Button {
                        text:"Add accidentals"
                        anchors {
                              top: col1.bottom
                              topMargin: 15
                              left: rect1.left
                              leftMargin: 10
                        }
                        onClicked: {
                              configDialog.visible = false;
                              var hasError = false;

                              // set configuration
                              useBracket = optUseBracket.checked;

                              // set type
                              if (optNextMeasure.checked) {
                                    operationMode = typeNextMeasure;
                              } else if (optNumMeasures.checked) {
                                    operationMode = typeNumMeasures;
                                    numMeasures = valNumMeasures.value;
                              } else if (optEvent.checked) {
                                    operationMode = typeEvent;
                                    eventTypes = 0;
                                    if (optFullRest.checked) {
                                          eventTypes |= eventFullRest;
                                    }
                                    if (optDoubleBar.checked) {
                                          eventTypes |= eventDoubleBar;
                                    }
                                    if (optRehearsalMark.checked) {
                                          eventTypes |= eventRehearsalMark;
                                    }
                                    if (optEndScore.checked) {
                                          eventTypes != eventEndScore;
                                    }
                                    if (!eventTypes) {
                                          // show error: at least one item needs to be selected
                                          //console.log("ERROR: configuration");
                                          hasError = true;
                                          errorDialog.text = "No terminating event selected";
                                          errorDialog.visible = true;
                                    }
                              } else if (optDodecaphonic.checked) {
                                    operationMode = typeDodecaphonic;
                              }

                              if (!hasError) {
                                    curScore.startCmd();
                                    addAcc();
                                    curScore.endCmd();
                              }
                        }
                  }

                  Button {
                        text: "Cancel"
                        anchors {
                              top: col1.bottom
                              topMargin: 15
                              right: rect1.right
                              rightMargin: 10
                        }
                        onClicked: {
                              configDialog.visible = false;
                        }
                  }
            }
      }

      // if nothing is selected process whole score
      property bool processAll: false

      // function tpcName
      //
      // return name of note

      function tpcName(tpc) {
            var tpcNames = new Array(
                  "Fbb", "Cbb", "Gbb", "Dbb", "Abb", "Ebb", "Bbb",
                  "Fb",   "Cb",   "Gb",   "Db",   "Ab",   "Eb",   "Bb",
                  "F",     "C",     "G",     "D",     "A",     "E",     "B",
                  "F#",   "C#",   "G#",   "D#",   "A#",    "E#",   "B#",
                  "F##", "C##", "G##", "D##", "A##",  "E##",  "B##"
             );

            return(tpcNames[tpc+1]);
      }

      // function getEndStaffOfPart
      //
      // return the first staff that does not belong to
      // the part containing given start staff.

      function getEndStaffOfPart(startStaff) {
            var startTrack = startStaff * 4;
            var parts = curScore.parts;

            for(var i = 0; i < parts.length; i++) {
                  var part = parts[i];

                  if( (part.startTrack <= startTrack)
                        && (part.endTrack > startTrack) ) {
                        return(part.endTrack/4);
                  }
            }

            // not found!
            console.log("error: part for " + startStaff + " not found!");
            Qt.quit();
      }

      // function addAccidental
      //
      // add correct accidental to note

      function addAccidental(note) {
            if(note.accidental == null) {
                  // calculate type of needed accidental
                  var accidental=Accidental.NONE;
                  if(note.tpc < 6) {
                        accidental = Accidental.FLAT2;
                  } else if(note.tpc < 13) {
                        accidental = Accidental.FLAT;
                  } else if(note.tpc < 20) {
                        accidental = Accidental.NATURAL;
                  } else if(note.tpc < 27) {
                        accidental = Accidental.SHARP;
                  } else {
                        accidental = Accidental.SHARP2;
                  }
                  note.accidentalType = accidental;
                  // put bracket on accidental
                  note.accidental.hasBracket = useBracket;
            }
      }

      // function processNote
      //
      // for each measure we create a table that contains 
      // the actual 'noteName' of each 'noteClass'
      //
      // a 'noteClass' is the natural name of a space
      // or line of the staff and the octave:
      // C5, F6, B3 are 'noteClass'
      //   
      // a 'noteName' would be C, F#, Bb for example
      // (we don't need the octave here)
      //
      // we also remember the measure number that note was found
      // if we operate in typeNumMeasures mode. Thus:
      //
      // curMeasureArray[<noteClass>] = [<noteName>,<measureNum>]

      function processNote(note,prevMeasureArray,curMeasureArray,curMeasureNum) {
            var octave=Math.floor(note.pitch/12);

            // use tpc1 instead of tpc for octave correction
            // since this will also work for transposing instruments
            // correct octave for Cb and Cbb
            if(note.tpc1 == 7 || note.tpc1 == 0) {
                  octave++; // belongs to higher octave
            }
            // correct octave for B# and B##
            if(note.tpc1 == 26 || note.tpc1 == 33) {
                  octave--; // belongs to lower octave
            }

            var noteName = tpcName(note.tpc);
            var noteClass = noteName.charAt(0)+octave;

            // remember note for next measure
            curMeasureArray[noteClass]=[noteName,curMeasureNum];
            console.log("added "+noteClass+" = "+noteName+","+curMeasureNum);

            if (operationMode == typeDodecaphonic) {
                  addAccidental(note);
            } else if (typeof prevMeasureArray[noteClass] !== 'undefined') {
                  // check if current note needs courtesy acc
                  if(prevMeasureArray[noteClass][0] != noteName) {
                        // this note needs an accidental
                        // if there's none present anyway
                        addAccidental(note);
                  }
                  // delete entry to make sure we don't create the
                  // same accidental again in the same measure
                  delete prevMeasureArray[noteClass];
            }
      }

      // function processPart
      //
      // do the actual work: process all given tracks in parallel
      // add courtesy accidentals where needed.
      //
      // We go through all tracks simultaneously, because we also want courtesy
      // accidentals for notes across different staves when they are in the 
      // same octave and for notes of different voices in the same octave

      function processPart(cursor,endTick,startTrack,endTrack) {
            if(processAll) {
                  // we need to reset track first, otherwise
                  // rewind(0) doesn't work correctly
                  cursor.track=0; 
                  cursor.rewind(0);
            } else {
                  cursor.rewind(1);
            }

            var curMeasureNum = 0;
            var segment = cursor.segment;

            var curMeasureArray = new Array();
            var prevMeasureArray = new Array();

            // we use a segment, because the cursor always proceeds to 
            // the next element in the given track and we don't know 
            // in which track the next element is.

            while(segment && (processAll || segment.tick < endTick)) {
                  // we search for key signatures and bar lines
                  // in first voice of first staff:
                  var keySigTrack = startTrack - (startTrack % 4);

                  // check for new measure
                  if(segment.elementAt(keySigTrack)
                     && segment.elementAt(keySigTrack).type == Element.BAR_LINE) {
                       
                        curMeasureNum++;
                        if (operationMode == typeNextMeasure) {
                              prevMeasureArray = curMeasureArray;
                              curMeasureArray = new Array();
                        } else if (operationMode == typeNumMeasures) {
                              // delete all entries that are too old
                              var toDelete = [];
                              for (var n in prevMeasureArray) {
                                    if (curMeasureNum - prevMeasureArray[n][1] > numMeasures) {
                                          toDelete.push(n);
                                    }
                              }
                              // now delete, otherwise iterating (n in prevMeasureArray) will not work
                              for (var x = 0; x < toDelete.length; x++)
                                    delete prevMeasureArray[toDelete[x]];

                              // copy entries from curMeasureArray
                              for (var n in curMeasureArray) {
                                    prevMeasureArray[n] = curMeasureArray[n];
                              }
                              // reset curMeasureArray
                              curMeasureArray = new Array();
                        }
                  }

                  // check for new key signature
                  // we only do this for the first track of the first staff
                  // this means we miss the event of having two different
                  // key signatures in different staves of the same part
                  // This remains for future version if needed
                  // we look inside this loop to make sure we don't miss
                  // any segments. This could be improved for speed.
                  // A KeySig that has generated == true was created by
                  // layout, and is probably at the beginning of a new line
                  // so we don't need it.
 
                  if (segment.elementAt(keySigTrack) 
                    && segment.elementAt(keySigTrack).type == Element.KEYSIG
                    && (!segment.elementAt(keySigTrack).generated)) {
                        //console.log("found KEYSIG");
                        // just forget the previous measure info 
                        // to not generate any courtesy accidentals
                        prevMeasureArray = new Array();
                  }

                  // check for rehearsal mark
                  if (segment.elementAt(0)
                    && segment.elementAt(0).type == Element.REHEARSAL_MARK) {
                        console.log("found rehearsal mark");
                  }

                  for(var track=startTrack; track<endTrack; track++) {
                        // look for notes and grace notes
                        if(segment.elementAt(track) && segment.elementAt(track).type == Element.CHORD) {
                              // process graceNotes if present
                              if(segment.elementAt(track).graceNotes.length > 0) {
                                    var graceChords = segment.elementAt(track).graceNotes;
                                    
                                    for(var j=0;j<graceChords.length;j++) {
                                          var notes = graceChords[j].notes;
                                          for(var i=0;i<notes.length;i++) {
                                                processNote(notes[i],prevMeasureArray,curMeasureArray,curMeasureNum);
                                          }
                                    }
                              }

                              // process notes
                              var notes = segment.elementAt(track).notes;
                              
                              for(var i=0;i<notes.length;i++) {
                                    processNote(notes[i],prevMeasureArray,curMeasureArray,curMeasureNum);
                              }
                        }
                  }
                  segment=segment.next;
            }
      }

      function addAcc() {
            console.log("start add courtesy accidentals");

            //curScore.startCmd();

             if (typeof curScore === 'undefined' || curScore == null) {
                   console.log("error: no score!");	     
                   Qt.quit();
             }

            // find selection
            var startStaff;
            var endStaff;
            var endTick;
            
            var cursor = curScore.newCursor();
            cursor.rewind(1);
            if(!cursor.segment) {
                  // no selection
                  console.log("no selection: processing whole score");
                  processAll = true;
                  startStaff = 0;
                  endStaff = curScore.nstaves;
            } else {
                  startStaff = cursor.staffIdx;
                  cursor.rewind(2);
                  endStaff = cursor.staffIdx+1;
                  endTick = cursor.tick;
                  if(endTick == 0) {
                        // selection includes end of score
                        // calculate tick from last score segment
                        endTick = curScore.lastSegment.tick + 1;
                  }
                  cursor.rewind(1);
                  console.log("Selection is: Staves("+startStaff+"-"+endStaff+") Ticks("+cursor.tick+"-"+endTick+")");
            }      

            console.log("ProcessAll is "+processAll);

            // go through all staves of a part simultaneously
            // find staves that belong to the same part

            var curStartStaff = startStaff;

            while(curStartStaff < endStaff) {
                  // find end staff for this part
                  var curEndStaff = getEndStaffOfPart(curStartStaff);

                  if(curEndStaff > endStaff) {
                        curEndStaff = endStaff;
                  }

                  // do the work
                  processPart(cursor,endTick,curStartStaff*4,curEndStaff*4);

                  // next part
                  curStartStaff = curEndStaff;
            }

            //curScore.doLayout();
            //curScore.endCmd();

            console.log("end add courtesy accidentals");
            Qt.quit();
      }

      onRun: { 
            //addAcc();
      }
}
