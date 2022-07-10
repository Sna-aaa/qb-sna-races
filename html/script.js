var CreatorActive = false;
var RaceActive = false;

$(document).ready(function(){
    window.addEventListener('message', function(event){
        var data = event.data;

        if (data.action == "Update") {
            UpdateUI(data.type, data);
        }
    });
});

function secondsTimeSpanToHMS(s) {
    var h = Math.floor(s/36000); //Get whole hours
    s -= h*36000;
    var m = Math.floor(s/600); //Get remaining minutes
    s -= m*600;
    var se = Math.floor(s/10); //Get remaining seconds
    s -= se*10;
    return h+":"+(m < 10 ? '0'+m : m)+":"+(se < 10 ? '0'+se : se)+":"+s; //zero padding on minutes and seconds
}

function UpdateUI(type, data) {
    if (type == "creator") {
        if (data.active) {
            if (!CreatorActive) {
                CreatorActive = true;
                $(".editor").fadeIn(300);
            }
            $("#editor-racename").html('Race: ' + data.data.name);
            $("#editor-checkpoints").html('Checkpoints: ' + data.data.checkpoints.length + ' / ?');
            $("#editor-keys-tiredistance").html('<span style="color: rgb(0, 201, 0);">+ ] </span> / <span style="color: rgb(255, 43, 43);">- [</span> - Tire Distance ['+data.data.TireDistance+'.0]');
            if (data.data.ClosestCheckpoint !== undefined && data.data.ClosestCheckpoint !== 0) {
                $("#editor-keys-delete").html('<span style="color: rgb(255, 43, 43);">8</span> - Delete Checkpoint [' + data.data.ClosestCheckpoint + ']');
            } else {
                $("#editor-keys-delete").html("");
            }
        } else {
            CreatorActive = false;
            $(".editor").fadeOut(300);
        }
    } else if (type == "race") {
        if (data.active) {
            if (!RaceActive) {
                RaceActive = true;
                $(".editor").hide();
                $(".race").fadeIn(300);
            }
            $("#race-position").html('Position: ' + data.data.Position + ' / ' + data.data.Drivers);
            $("#race-checkpoints").html('Checkpoint: ' + data.data.CurrentCheckpoint + ' / ' + data.data.TotalCheckpoints);
            if (data.data.TotalLaps == 1) {
                $("#race-lap").html('Laps: Sprint');
            } else {
                $("#race-lap").html('Laps: ' + data.data.CurrentLap + ' / ' + data.data.TotalLaps);
            }
            if (data.data.Type == "drift") {
                $("#race-time").html('Lap Points: ' + data.data.LapValue);
                if (data.data.BestLap !== 0) {
                    $("#race-besttime").html('Best Score: ' + data.data.BestLapValue);
                } else {
                    $("#race-besttime").html('Best Score: N/A');
                }
                $("#race-totaltime").html('Total Score: ' + data.data.TotalValue);
            } else {
                $("#race-time").html('Lap Time: ' + secondsTimeSpanToHMS(data.data.LapValue));
                if (data.data.BestLap !== 0) {
                    $("#race-besttime").html('Best Lap: ' + secondsTimeSpanToHMS(data.data.BestLapValue));
                } else {
                    $("#race-besttime").html('Best Lap: N/A');
                }
                $("#race-totaltime").html('Total Time: ' + secondsTimeSpanToHMS(data.data.TotalValue));
            }
        } else {
            RaceActive = false;
            $(".editor").hide();
            $(".race").fadeOut(300);
        }
    }
}