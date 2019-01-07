//= require datatables/jquery.dataTables

// optional change '//' --> '//=' to enable

// require datatables/extensions/AutoFill/dataTables.autoFill
//= require datatables/extensions/Buttons/dataTables.buttons
//= require datatables/extensions/Buttons/buttons.html5
//= require datatables/extensions/Buttons/buttons.print
//= require datatables/extensions/Buttons/buttons.colVis
// require datatables/extensions/Buttons/buttons.flash
// require datatables/extensions/ColReorder/dataTables.colReorder
// require datatables/extensions/FixedColumns/dataTables.fixedColumns
// require datatables/extensions/FixedHeader/dataTables.fixedHeader
// require datatables/extensions/KeyTable/dataTables.keyTable
//= require datatables/extensions/Responsive/dataTables.responsive
// require datatables/extensions/RowGroup/dataTables.rowGroup
// require datatables/extensions/RowReorder/dataTables.rowReorder
// require datatables/extensions/Scroller/dataTables.scroller
// require datatables/extensions/Select/dataTables.select

//= require datatables/dataTables.material


//Global setting and initializer

$.extend( $.fn.dataTable.defaults, {
  responsive: true,
  buttons: [
    'csv', 'print'
  ],
  language: {
    paginate: {
      previous: '<',
      next:     '>'
    }
  },
  lengthMenu: [ [10, 25, 50, -1], [ 10, 25, 50, 'All'] ],
  pageLength: -1,
  dom:
    "<'row'lf>" +
    "<'#dttbl.row'trip>" +
    "<'row'<'col s12'B>>"
});


$(document).on('preInit.dt', function(e, settings) {
  var api, table_id, url;
  api = new $.fn.dataTable.Api(settings);
  table_id = "#" + api.table().node().id;
  url = $(table_id).data('source');
  if (url) {
    return api.ajax.url(url);
  }
});

// init on turbolinks load
$(document).on('turbolinks:load', function() {
  $("table[id^=dttb-]").DataTable( {
    responsive: true
  } );
  $("table[id^=dttb1-]").DataTable( {
    responsive: true,
    order: [1, 'desc'],
    columnDefs: [ {
      "searchable": false,
      "orderable": false,
      "targets": [0, -1, -2]
    }],
    dom: "<'#dttbl.row'tr>"
  } );
  $("table[id^=dttb_simple-]").DataTable( {
    responsive: true,
    order: [0, 'desc'],
    columnDefs: [ {
      "searchable": false,
      "orderable": false,
      "targets": [-1]
    }],
    dom: "<'#dttbl.row'tr>"
  } );
});

// turbolinks cache fix
$(document).on('turbolinks:before-cache', function() {
  var dataTable = $($.fn.dataTable.tables(true)).DataTable();
  if (dataTable !== null) {
    dataTable.clear();
    dataTable.destroy();
    return dataTable = null;
  }
});
