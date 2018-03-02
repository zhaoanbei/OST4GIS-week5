/* =====================
 Copy your code from Week 4 Lab 2 Part 2 part2-app-state.js in this space
===================== */
//var downloadData = $.ajax("https://raw.githubusercontent.com/CPLN-692-401/datasets/master/json/philadelphia-crime-snippet.json");
//var prt = function(response){console.log(JSON.parse(response));}

// Write a function to prepare your data (clean it up, organize it as you like, create fields, etc)
// No modification
var map = L.map('map', {
  center: [39.9522, -75.1639],
  zoom: 14
});

var Stamen_TonerLite = L.tileLayer('http://stamen-tiles-{s}.a.ssl.fastly.net/toner-lite/{z}/{x}/{y}.{ext}', {
  attribution: 'Map tiles by <a href="http://stamen.com">Stamen Design</a>, <a href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a> &mdash; Map data &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>',
  subdomains: 'abcd',
  minZoom: 0,
  maxZoom: 20,
  ext: 'png'
}).addTo(map);


var parseData = function(data) {return JSON.parse(data)}

// Write a function to use your parsed data to create a bunch of marker objects (don't plot them!)
var makeMarkers = function(data,lat,lon) {
  return _.map(data, function(item) {
    return L.marker([parseFloat(item[lat]), parseFloat(item[lon])]);
  })
};


// Now we need a function that takes this collection of markers and puts them on the map
var plotMarkers = function(markers) {
  return _.map(markers, function(marker){
    console.log(marker);
    return marker.addTo(map)
  })
};


/* =====================
  Define the function removeData so that it clears the markers you've written
  from the map. You'll know you've succeeded when the markers that were
  previously displayed are (nearly) immediately removed from the map.

  In Leaflet, the syntax for removing one specific marker looks like this:

  map.removeLayer(marker);

  In real applications, this will typically happen in response to changes to the
  user's input.
===================== */
var removeMarkers = function(markers) {
  _.each(markers, function (marker){ map.removeLayer(marker) })
}
// Look to the bottom of this file and try to reason about what this function should look like
$('#map-button').click(function(e) {
  removeMarkers();
  var url = $('#url-input').val();
  console.log(e);
  var downloadData = $.ajax(url);
  var lat = $('#Lat-input').val();
  var lon = $('#Lon-input').val();
  console.log(lat);
  downloadData.done(function(data) {
    var parsed = parseData(data);
    console.log("parsed", parsed)
    var markers = makeMarkers(parsed,lat,lon);
    console.log("markers", markers)
    plotMarkers(markers);
  });
});


/* =====================
  Optional, stretch goal
  Write the necessary code (however you can) to plot a filtered down version of
  the downloaded and parsed data.

  Note: You can add or remove from the code at the bottom of this file for the stretch goal.
===================== */

/* =====================
 Leaflet setup - feel free to ignore this
===================== */
