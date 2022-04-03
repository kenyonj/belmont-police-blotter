window.onload = function () {
  loadData();
  updateStreetsDataList();
  conditionallyShowMapOrList();
  setupPaginationButtons();
}

function loadData() {
  return retrievePlots().then(markers => {
    createTable(markers);
    var mapOptions = {
      center: new google.maps.LatLng(markers[0].lat, markers[0].lng),
      zoom: 8,
      mapTypeId: google.maps.MapTypeId.ROADMAP
    };
    var infoWindow = new google.maps.InfoWindow();
    var latlngbounds = new google.maps.LatLngBounds();
    var map = new google.maps.Map(document.getElementById("dvMap"), mapOptions);

    updateIncidentCount(markers.length);

    for (var thisMarker of markers) {
      var data = thisMarker
      var myLatlng = new google.maps.LatLng(data.lat, data.lng);
      var marker = new google.maps.Marker({
        position: myLatlng,
        map: map,
        title: data.title
      });
      (function (marker, data) {
        google.maps.event.addListener(marker, "click", function (e) {
          infoWindow.setContent("<div style = 'width:200px;min-height:40px'>" + data.description + "</div>");
          infoWindow.open(map, marker);
        });
      })(marker, data);
      latlngbounds.extend(marker.position);
    }
    var bounds = new google.maps.LatLngBounds();
    map.setCenter(latlngbounds.getCenter());
    map.fitBounds(latlngbounds);
  }).
  catch((err) => {
    console.log(`loadData -> retrievePlots -> Error: ${err}`)
  });
}

function retrievePlots() {
  const urlSearchParams = new URLSearchParams(window.location.search);
  const params = Object.fromEntries(urlSearchParams.entries());
  const incidentsUrl = new URL("https://bpb-api.heyo.pw/api/index");
  Object.keys(params).forEach(key => {
    if (params[key]) {
      if (key !== "view") {
        incidentsUrl.searchParams.append(key, params[key])
      }

      const formSelection = document.getElementById(`${key}-${params[key]}`)

      if (formSelection) {
        formSelection.selected = true;
      }
    }
  });

  const streetElement = document.getElementById("street-name-input")

  if (streetElement && params["distance_from"] != undefined && params["distance_from"] != "") {
    streetElement.value = params["distance_from"]
    const streetFilterButton = document.getElementById("street-filter-button")

    if (streetFilterButton) {
      streetFilterButton.click()
    }
  }

  if (!params.hasOwnProperty("limit")) {
    incidentsUrl.searchParams.append("limit", 20)
  }

  return fetch(incidentsUrl).
    then(response => response.json()).
    then(data => {
      return data.items.map(({date, number, latitude, longitude, type, location, time}) => {
        const realDate = new Date(date);
        const year = realDate.getFullYear();
        const month = (realDate.getMonth() + 1).toString().padStart(2, "0");
        const day = realDate.getDate().toString().padStart(2, "0");

        return {
          year, month, day,
          number,
          type,
          location,
          time,
          "title": `Incident: ${number}`,
          "lat": latitude,
          "lng": longitude,
          "description": `Type: ${type}<br>
                      Date: ${year}/${month}/${day}<br>
                      Time: ${time}<br>
                      Location: ${location}<br>
                      More information: <a href='/incidents/${year}/${month}/${day}/${number}'>${number}</a>`,
        }
      })
    }).
    catch((err) => {
      console.log(`retrievePlots -> fetch -> Error: ${err}`)
    });
}

function createTable(markers) {
  const table = document.getElementById("incident-list");

  if (table) {
    markers.forEach(marker => table.appendChild(createTableRow(marker)));
  }
}

function createTableRow(marker) {
  const row = document.createElement("tr");
  const id = document.createElement("td");
  const type = document.createElement("td");
  const date = document.createElement("td");
  const time = document.createElement("td");
  const streetLocation = document.createElement("td");

  row.setAttribute(
    "onclick",
    `window.location="/incidents/${marker.year}/${marker.month}/${marker.day}/${marker.number}";`
  );
  row.setAttribute("style", "cursor: pointer;");
  id.innerText = marker.number;
  type.innerText = marker.type;
  date.innerText = `${marker.year}/${marker.month}/${marker.day}`;
  time.innerText = marker.time;
  streetLocation.innerText = marker.location;

  row.appendChild(id);
  row.appendChild(type);
  row.appendChild(date);
  row.appendChild(time);
  row.appendChild(streetLocation);

  return row;
}

function updateIncidentCount(count) {
  const countContainer = document.getElementById("incident-count");

  if (countContainer) {
    countContainer.innerText = count.toLocaleString();
  }
}

function updateStreetsDataList() {
  const dataListContainer = document.getElementById("streets");

  if (dataListContainer) {
    const streets = getStreets();

    streets.forEach(street => dataListContainer.appendChild(createStreetOption(street)));
  }
}

function createStreetOption(street) {
  const option = document.createElement("option");
  option.value = street;
  option.innerText = street;
  return option;
}

function conditionallyShowMapOrList() {
  const listButton = document.getElementById("nav-list-tab");
  const mapButton = document.getElementById("nav-map-tab");
  const hiddenInput = document.getElementById("view-input");

  if (hiddenInput) {
    hiddenInput.value = "list";
  } else {
    hiddenInput.value = "map";
  }

  if (listButton && viewIsList()) {
    listButton.click();
  } else if (mapButton) {
    mapButton.click();
  }
}

function setHiddenMapOrListInput(tabName) {
  const hiddenInput = document.getElementById("view-input");

  if (hiddenInput) {
    hiddenInput.value = tabName;
  }
}

function viewIsList() {
  return window.location.search.includes("view=list");
}

function setupPaginationButtons() {
  const prevPageContainer = document.getElementById("prev-page-container");
  const nextPageContainer = document.getElementById("next-page-container");
  const prevPageLink = document.getElementById("prev-page-link");
  const nextPageLink = document.getElementById("next-page-link");

  if (prevPageContainer && nextPageContainer && prevPageLink && nextPageLink) {
    const urlSearchParams = new URLSearchParams(window.location.search);
    const params = Object.fromEntries(urlSearchParams.entries());

    if (params["offset"] && params["offset"] > 0) {
      prevPageContainer.classList.remove("disabled");
      prevPageLink.ariaDisabled = false;
      const prevOffset = Number(params["offset"]) - Number(params["limit"]);
      const nextOffset = Number(params["offset"]) + Number(params["limit"]);
      urlSearchParams.set("offset", prevOffset);
      const prevNewRelativePathQuery = window.location.pathname + '?' + urlSearchParams.toString();
      urlSearchParams.set("offset", nextOffset);
      const nextNewRelativePathQuery = window.location.pathname + '?' + urlSearchParams.toString();
      prevPageLink.setAttribute("href", prevNewRelativePathQuery);
      nextPageLink.setAttribute("href", nextNewRelativePathQuery);
    } else {
      prevPageContainer.classList.add("disabled");
      prevPageLink.ariaDisabled = true;
      urlSearchParams.set("offset", params["limit"] || 0);
      const nextNewRelativePathQuery = window.location.pathname + '?' + urlSearchParams.toString();
      nextPageLink.setAttribute("href", nextNewRelativePathQuery);
    }
  }
}

function getStreets() {
  return [
    "A ST",
    "ACORN PARK DR",
    "ACORN ST",
    "ADAMS ST",
    "AGASSIZ AVE",
    "AGASSIZ ST",
    "ALBERT AVE",
    "ALEXANDER AVE",
    "ALMA AVE",
    "AMELIA ST",
    "AMHERST RD",
    "ANIS RD",
    "ARTHUR RD",
    "ASH ST",
    "AUDREY RD",
    "AUDUBON LN",
    "B ST",
    "BACON RD",
    "BAKER ST",
    "BANKS ST",
    "BARBARA RD",
    "BARNARD RD",
    "BARTLETT AVE",
    "BAY STATE RD",
    "BAYBERRY LN",
    "BEATRICE CIR",
    "BECKET RD",
    "BEECH ST",
    "BELLEVUE RD",
    "BELLINGTON ST",
    "BELMONT CIR",
    "BELMONT ST",
    "BENJAMIN RD",
    "BENTON RD",
    "BERWICK ST",
    "BETTS RD",
    "BIRCH HILL RD",
    "BIRCH ST",
    "BLAKE ST",
    "BLANCHARD RD",
    "BOW RD",
    "BRADFORD RD",
    "BRADLEY RD",
    "BRANCHAUD RD",
    "BRETTWOOD RD",
    "BRIGHT RD",
    "BRIGHTON ST",
    "BROAD ST",
    "BROOKSIDE AVE",
    "BURNHAM ST",
    "C ST",
    "CAMBRIDGE ST",
    "CANDLEBERRY LN",
    "CARLETON CIR",
    "CARLETON RD",
    "CEDAR RD",
    "CENTRE AVE",
    "CHANDLER ST",
    "CHANNING RD",
    "CHARLES ST",
    "CHENERY TERR",
    "CHERRY ST",
    "CHESTER RD",
    "CHESTNUT ST",
    "CHILTON ST",
    "CHOATE RD",
    "CHURCH ST",
    "CLAFLIN ST",
    "CLAIREMONT RD",
    "CLARENDON RD",
    "CLARK LANE",
    "CLARK ST",
    "CLIFTON ST",
    "CLOVER ST",
    "CLYDE ST",
    "COLBY ST",
    "COLONIAL TERR",
    "COMMON ST",
    "CONCORD AVE",
    "CONCORD TPK",
    "COOLIDGE RD",
    "COTTAGE ST",
    "COUNTRY CLUB LN",
    "COWDIN ST",
    "CREELEY RD",
    "CRESCENT RD",
    "CRESTVIEW RD",
    "CROSS ST",
    "CUMBERLAND RD",
    "CUSHING AVE",
    "CUTTER ST",
    "DALTON RD",
    "DANA RD",
    "DANTE AVE",
    "DARTMOUTH ST",
    "DAVIS RD",
    "DAVIS ST",
    "DAY SCHOOL LN",
    "DEAN ST",
    "DORSET RD",
    "DOUGLAS RD",
    "DREW RD",
    "DUNBARTON RD",
    "DUNDONALD RD",
    "EDGEMOOR RD",
    "EDMUNDS WAY",
    "EDWARD ST",
    "ELIOT RD",
    "ELIZABETH RD",
    "ELM ST",
    "EMERSON ST",
    "ERICSSON ST",
    "ERNEST RD",
    "ESSEX RD",
    "EVERGREEN WAY",
    "EXETER ST",
    "FAIRMONT ST",
    "FAIRVIEW AVE",
    "FALMOUTH ST",
    "FARM RD",
    "FARNHAM ST",
    "FIELDMONT RD",
    "FITZMAURICE CIR",
    "FLANDERS RD",
    "FLETCHER RD",
    "FLETT RD",
    "FOSTER RD",
    "FRANCIS ST",
    "FRANKLIN ST",
    "FREDERICK ST",
    "FROST RD",
    "GALE RD",
    "GARDEN ST",
    "GARFIELD RD",
    "GARRISON RD",
    "GEORGE ST",
    "GILBERT RD",
    "GILMORE RD",
    "GLENDALE RD",
    "GLENN RD",
    "GODEN ST",
    "GORDON TERR",
    "GORHAM RD",
    "GRANT AVE",
    "GREENSBROOK WAY",
    "GREYBIRCH CIR",
    "GREYBIRCH PARK",
    "GROSVENOR RD",
    "GROVE ST",
    "HAMILTON RD",
    "HAMMOND RD",
    "HARDING AVE",
    "HARRIET AVE",
    "HARRIS ST",
    "HARTLEY RD",
    "HARVARD RD",
    "HASTINGS RD",
    "HAWTHORNE ST",
    "HAY RD",
    "HENRY ST",
    "HERBERT RD",
    "HERMON ST",
    "HICKORY LN",
    "HIGHLAND RD",
    "HILL RD",
    "HILLCREST RD",
    "HILLSIDE TERR",
    "HINCKLEY WAY",
    "HITTINGER ST",
    "HOITT RD",
    "HOLDEN RD",
    "HOLT ST",
    "HOMER RD",
    "HORACE RD",
    "HORNE RD",
    "HOUGH RD",
    "HOUGHTON RD",
    "HOWARD ST",
    "HOWELLS RD",
    "HULL ST",
    "HURD RD",
    "HURLEY ST",
    "INDIAN HILL RD",
    "IRVING ST",
    "IVY RD",
    "JACKSON RD",
    "JACOB RD",
    "JASON RD",
    "JEANETTE AVE",
    "JONATHAN ST",
    "JUNIPER RD",
    "KENMORE RD",
    "KENT ST",
    "KILBURN RD",
    "KING ST",
    "KNOWLES RD",
    "KNOX ST",
    "LAKE ST",
    "LAMBERT RD",
    "LAMOINE ST",
    "LANTERN RD",
    "LARCH CIR",
    "LAUREL ST",
    "LAWNDALE ST",
    "LAWRENCE LN",
    "LEDGEWOOD PL",
    "LEICESTER RD",
    "LEONARD ST",
    "LESLIE RD",
    "LEWIS RD",
    "LEXINGTON ST",
    "LEXINGTON ST  STE 101",
    "LEXINGTON ST  STE 201",
    "LINCOLN CIR",
    "LINCOLN ST",
    "LINDEN AVE",
    "LITTLE POND RD",
    "LIVERMORE RD",
    "LOCUST ST",
    "LODGE RD",
    "LONG AVE",
    "LONGMEADOW RD",
    "LORIMER RD",
    "LORING ST",
    "LOUISE RD",
    "MADISON ST",
    "MANNIX CIR",
    "MAPLE ST",
    "MAPLE TERR",
    "MARION RD",
    "MARLBORO ST",
    "MARSH ST",
    "MAYFIELD RD",
    "MEADOWS LN",
    "MERRILL AVE",
    "MIDDLECOT ST",
    "MIDLAND ST",
    "MILL ST",
    "MILTON ST",
    "MOORE ST",
    "MORAINE ST",
    "MUNROE ST",
    "MYRTLE ST",
    "NEWCASTLE RD",
    "NEWTON ST",
    "OAK AVE",
    "OAK ST",
    "OAKLEY RD",
    "OAKMONT LN",
    "OLD CONCORD RD",
    "OLD MIDDLESEX RD",
    "OLIVER RD",
    "OLMSTED DR",
    "ORCHARD CIR",
    "ORCHARD ST",
    "OXFORD AVE",
    "OXFORD CIR",
    "PALFREY RD",
    "PARK AVE",
    "PARK RD",
    "PARTRIDGE LN",
    "PAYSON RD",
    "PAYSON TERR",
    "PEARL ST",
    "PEARSON RD",
    "PEQUOSSETTE RD",
    "PHILIP RD",
    "PIERCE RD",
    "PILGRIM RD",
    "PINE ST",
    "PINEHURST RD",
    "PLEASANT ST",
    "PLYMOUTH AVE",
    "POND ST",
    "POPLAR ST",
    "PREBLE GARDENS RD",
    "PRENTISS LN",
    "PRINCE ST",
    "PROSPECT ST",
    "RADCLIFFE RD",
    "RALEIGH RD",
    "RANDOLPH ST",
    "RAYBURN RD",
    "REGENT RD",
    "RICHARDSON RD",
    "RICHMOND RD",
    "RIDGE RD",
    "RIPLEY RD",
    "ROBIN WOOD RD",
    "ROCKMONT RD",
    "ROSS RD",
    "ROYAL RD",
    "RUSSELL TERR",
    "RUTLEDGE RD",
    "S COTTAGE RD",
    "S COTTAGE RD U101",
    "S COTTAGE RD U102",
    "S COTTAGE RD U201",
    "S COTTAGE RD U202",
    "S COTTAGE RD U203",
    "SABINA WAY",
    "SANDRICK RD",
    "SARGENT RD",
    "SCHOOL ST",
    "SCOTT RD",
    "SELWYN RD",
    "SHADY BROOK LN",
    "SHARPE RD",
    "SHAW RD",
    "SHEAN RD",
    "SHERMAN ST",
    "SIMMONS AVE",
    "SKAHAN RD",
    "SLADE ST",
    "SNAKE HILL RD",
    "SOMERSET ST",
    "SPINNEY TERR",
    "SPRING VALLEY RD",
    "SPRINGFIELD ST",
    "SPRUCE ST",
    "ST JAMES COURT",
    "STABLES WAY",
    "STANLEY RD",
    "STATLER RD",
    "STAUNTON RD",
    "STEARNS RD",
    "STELLA RD",
    "STEWART TERR",
    "STONE RD",
    "STONY BROOK RD",
    "STULTS RD",
    "SUMMIT RD",
    "SUMNER LN",
    "SUNNYSIDE PL",
    "SYCAMORE ST",
    "TAYLOR RD",
    "TEMPLE ST",
    "THAYER RD",
    "THAYER ST",
    "THINGVALLA AVE",
    "THOMAS ST",
    "TOBEY RD",
    "TOWNSEND RD",
    "TRAPELO RD",
    "TRAPELO RD UNIT 21",
    "TROWBRIDGE ST",
    "TROY RD",
    "TYLER RD",
    "UNDERWOOD ST",
    "UNITY AVE",
    "UPLAND RD",
    "VALE RD",
    "VAN NESS RD",
    "VERNON RD",
    "VILLAGE HILL RD",
    "VINCENT AVE",
    "WALNUT ST",
    "WARWICK RD",
    "WASHINGTON ST",
    "WATERHOUSE RD",
    "WATSON RD",
    "WAVERLEY ST",
    "WAVERLEY TERR",
    "WEBER RD",
    "WELLESLEY RD",
    "WELLINGTON LN",
    "WEST ST",
    "WESTLUND RD",
    "WHITCOMB ST",
    "WHITE ST",
    "WHITE TERR",
    "WILEY RD",
    "WILLISTON RD",
    "WILLOW ST",
    "WILSON AVE",
    "WINN ST",
    "WINSLOW RD",
    "WINTER ST",
    "WINTHROP RD",
    "WOODBINE RD",
    "WOODFALL RD",
    "WOODLAND ST",
    "WOODS RD",
    "WORCESTER ST",
    "YORK RD",
  ];
}
