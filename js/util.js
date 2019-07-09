/**********這個檔案裡是一些公用的函數**********/

/**********全域變數**********/
var sServerBaseURL = "./";	//Server端接收 request 的 URL 路徑
var bIsDebugMode = true;	//是否為開發模式
var iDefaultTransactionFeeBtcTestnet = 0;	//單位是 sat/byte
var iDefaultTransactionFeeBtcMainnet = 32;	//單位是 sat/byte

/**********取得 server API 的 base URL**********/
function getServerBaseURL(){
	return sServerBaseURL;
}	//function getServerBaseURL(){

/**********判斷是否為開發模式**********/
function isDebugMode(){
	return bIsDebugMode;
}	//function isDebugMode(){

/**********取得BTC testnet預設的transaction fee**********/
function getDefaultTransactionFeeBtcTestnet(){
	return iDefaultTransactionFeeBtcTestnet;
}	//function getDefaultTransactionFeeBtcTestnet(){

/**********取得BTC mainnet預設的transaction fee**********/
function getDefaultTransactionFeeBtcMainnet(){
	return iDefaultTransactionFeeBtcMainnet;
}	//function getDefaultTransactionFeeBtcMainnet(){

/**********判斷字串是否為空值**********/
function beEmpty(s){
	return (s==null || s=='undefined' || s.length<1);
}	//function scrollToTop(){

/**********判斷字串是否有值**********/
function notEmpty(s){
	return (s!=null && s!='undefined' && s.length>0);
}	//function scrollToTop(){

/**********將金額字串加上千位的逗點**********/
function toCurrency(s){
	if (beEmpty(s)) return "";	//字串為空
	if (isNaN(s))	return s;	//不是數字，回覆原字串
	
	var i = 0;
	var j = 0;
	var k = 0;
	var l = 0;
	var s2 = "";
	s = trim(s);
	i = s.length;			//i為字串長度
	if (i<4) return s;		//長度太短，不用加逗點，直接回覆原字串
	j = Math.floor(i/3);	//j為字串長度除以3的商數
	k = i % 3;				//k為字串長度除以3的餘數
	s2 = "";
	if (k>0) s2 = s.substring(0, k);
	for (l=0;l<j;l++){
		s2 = s2 + (s2==""?"":",") + s.substring(k+(l*3), k+(l+1)*3);
	}
	return s2;
}

/**********將字串的空白去掉**********/
function trim(stringToTrim){
	return stringToTrim.replace(/^\s+|\s+$/g,"");
}

/**********判斷字串開頭是否為指定的字**********/
String.prototype.startsWith = function(prefix)
{
    return (this.substr(0, prefix.length) === prefix);
}
 
/**********判斷字串結尾是否為指定的字**********/
String.prototype.endsWith = function(suffix)
{
    return (this.substr(this.length - suffix.length) === suffix);
}
 
/**********判斷字串是否包含指定的字**********/
String.prototype.contains = function(txt)
{
    return (this.indexOf(txt) >= 0);
}

/**********取得某個 URL 參數的值，例如 http://target.SchoolID/set?text=abc **********/
function getParameterByName( name ){
	name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
	var regexS = "[\\?&]"+name+"=([^&#]*)";
	var regex = new RegExp( regexS );
	var results = regex.exec( window.location.href );
	if( results == null )
		return "";
	else
		return decodeURIComponent(results[1].replace(/\+/g, " "));
}

/**********檢查email格式是否正確**********/
function isEmail(email) { 
	var re = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    return re.test(email);
}

/**********顯示loading中的BlockUI**********/
function showBlockUI(){
/*
	$.blockUI({
		message: '<img src="images/loading.gif">資料更新中，請稍候...</img>',
		css: {
			border: 'none',
			background: 'none',
			color: '#00FF00'
		},
		overlayCSS:{
			backgroundColor: '#000000',
			opacity:         0.5,
			cursor:          'wait'
		}
	});
*/
	
	$.blockUI({ 
		message: 'Retrieving data, please wait...',
		css:{
			border: 'none',
			padding: '15px',
			backgroundColor: '#000',
			'-webkit-border-radius': '10px',
			'-moz-border-radius': '10px',
			opacity: 0.95,
			color: '#00FF00'
		}
	}); 

	//$('.blockOverlay').attr('title','以滑鼠點擊灰色區域可回到主畫面').click($.unblockUI);	//若加這一行且有使用JQuery UI Tooltip，則這一行字在BlockUI關閉後仍會殘留在IE畫面上(Chrome不會)
	//$('.blockOverlay').click($.unblockUI);	//若加這一行且有使用JQuery UI Tooltip，則這一行字在BlockUI關閉後仍會殘留在IE畫面上(Chrome不會)

}

/**********解除BlockUI**********/
function unBlockUI(){
	$.unblockUI();
}

/**********取得今天日期，格式為：2013/10/3**********/
function getCurrentDate(){
	var currDate = new Date();	//目前時間
	var txtCurrDate = currDate.getFullYear() + "-" + (currDate.getMonth()+1) + "-" + currDate.getDate();	//今天日期，格式為：2013/10/3
	return txtCurrDate;
}

/**********取得儲存在client端的變數值(從PC cookie或手機storage取得)**********/
function getLocalValue(key){
	var value = "";
	value = $.cookie(key);	//Browser，使用 cookie for JQuery
	if (beEmpty(value)) value="";
	return value;
}

/**********將變數值儲存在client端(PC cookie或手機storage)**********/
function setLocalValue(key, value, expires){	//若expires為空值，則僅存在此session中
	if (beEmpty(key)) return;
	$.cookie(key, value, { expires: expires, path: '/' });	//Browser，使用 cookie for JQuery，預設儲存30天
	return;
}

/**********顯示類似alert的message box**********/
function msgBox(msg, callbackClose){
	if ( typeof(dialogMessage) == "undefined"){
		$('body').append('<div id="dialogMessage" title="System Info."></div>');
	}
	$('#dialogMessage').html(msg);

	if (!beEmpty($('#dialogMessage').dialog( "instance" ))){
		$('#dialogMessage').dialog("destroy");
	}
	if (callbackClose==null){
		$( "#dialogMessage" ).dialog({
			modal: true,
			buttons: {
				Ok: function() {
					$( this ).dialog( "close" );
				}
			}
		});
	}else{
		$( "#dialogMessage" ).dialog({
			modal: true,
			buttons: {
				Ok: function() {
					$( this ).dialog( "close" );
					callbackClose
				}
			},
			close: callbackClose
		});
	}
}

/**********從 Server 擷取資料**********/
function getDataFromServer(sProgram, sData, sResponseType, SuccessCallback, bBlockUI, sMethod){
	/*****************************************************************
	sProgram		server端程式名稱，例如 xxx.jsp
	sData			要post給server的資料
	sResponseType	希望server端回覆的資料類型，可為 json 或 xml
	SuccessCallback	成功從server取得資料時的處理程式(function)
	bBlockUI		是否顯示BlockUI，若未輸入此參數則預設為顯示BlockUI
	*****************************************************************/
	if (beEmpty(bBlockUI)) bBlockUI = true;
	if (beEmpty(sData)) sData = "ResponseType=" + sResponseType; else sData += "&ResponseType=" + sResponseType;
	$.ajax({
		url: (sProgram.startsWith("http")?sProgram:sServerBaseURL + sProgram),
		type: (beEmpty(sMethod)?'POST':sMethod), //根據實際情況，可以是'POST'或者'GET'
		beforeSend : (bBlockUI==true?showBlockUI:null),
		complete   : (bBlockUI==true?unBlockUI:null),
		data: sData,
		dataType: sResponseType, //指定數據類型，注意server要有一行：response.setContentType("text/xml;charset=utf-8");
		timeout: 1200000, //設置timeout時間，以千分之一秒為單位，1000 = 1秒
		error: function (){	//錯誤提示
			msgBox('System busy!!');
		},
		success: function (data){ //ajax請求成功後do something with response data
			SuccessCallback(data);
		}	//success: function (data){ //ajax請求成功後do something with response data
	});	//$.ajax({
	return false;
}	//function sServerBaseURL(sProgram, sData, sResponseType, SuccessCallback){

function clearCookie(){	//清除 cookie 中的登入資料
	$.removeCookie('DPUserID');
	$.removeCookie('DPUserName');
	$.removeCookie('DPUserEmail');
	$.removeCookie('DPUserRole');
	return true;
}

//設定 grid 底下的Pager分頁列
function setGridNavBar(grid, pager, edit, add, del, search, refresh, view, position, cloneToTop){	//edit, add, del, search, refresh, view
		//Pager分頁列
		$(grid).navGrid(pager,
			// the buttons to appear on the toolbar of the grid
			//refresh設為 false，因為 loadonce: true，所以 refresh 不會重新從 server 撈資料
			{ edit: edit, add: add, del: del, search: search, refresh: refresh, view: view, position: position, cloneToTop: cloneToTop },
			// options for the Edit Dialog
			{
				editCaption: "The Edit Dialog",
				recreateForm: true,
				checkOnUpdate : true,
				checkOnSubmit : true,
				closeAfterEdit: true,
				errorTextFormat: function (data) {
					return 'Error: ' + data.responseText
				},
				beforeShowForm: function(frm) { 
					frm.find('.readonly').attr('readonly','readonly'); 
				},
				beforeSubmit: function(){showBlockUI();return [true,'']},
				afterSubmit: checkAjaxResultCode
			},
			// options for the Add Dialog
			{
				closeAfterAdd: true,
				recreateForm: true,
				errorTextFormat: function (data) {
					return 'Error: ' + data.responseText
				},
				beforeSubmit: function(){showBlockUI();return [true,'']},
				afterSubmit: checkAjaxResultCode
			},
			// options for the Delete Dailog
			{
				errorTextFormat: function (data) {
					return 'Error: ' + data.responseText
				},
				beforeSubmit: function(){showBlockUI();return [true,'']},
				afterSubmit: checkAjaxResultCode
			}
		);

}	//function setGridNavBar(grid, pager, edit, add, del, search, refresh, view, position, cloneToTop);	//edit, add, del, search, refresh, view

//從server撈取table資料後，檢查server回覆的resultCode
function checkAjaxLoadDataResultCode(data, status, xhr){	//從server撈取table資料後，檢查server回覆的resultCode
	//unBlockUI();
	if (!data.resultCode || !data.resultText){
		msgBox("Unable to get process result.");
		ga('send', 'event', $('#sysPageTitle').text() + '-load data', '無法取得資料撈取結果', '', 1);
		return;
	}else{
		if (data.resultCode!="00000"){
			msgBox("Process failed: " + data.resultText);
			ga('send', 'event', $('#sysPageTitle').text() + '-load data', '失敗', data.resultText, 1);
		}
	}
}	//function checkAjaxLoadDataResultCode(data, status, xhr){	//從server撈取table資料後，檢查server回覆的resultCode

//對 JQGrid 的資料進行 add/edit/del 後，parse server 回覆的執行結果
function checkAjaxResultCode(response, postdata){
	unBlockUI();
	//alert(JSON.stringify(response));
	var data = response.responseText;
	//alert(JSON.stringify(data));
	data = JSON.parse(data);
	//alert(data);
	if (!data.resultCode || !data.resultText){
		//msgBox("Unable to get process result.");
		ga('send', 'event', $('#sysPageTitle').text() + '-add/edit/delete', '無法取得執行結果', '', 1);
		return [false, "Unable to get process result.", ""];
	}else{
		if (data.resultCode=="00000"){
			ga('send', 'event', $('#sysPageTitle').text() + '-add/edit/delete', '成功', $('#sysUserID').val(), 1);
			msgBox("Success!<br>Please reload this page!");
			return [true, "", ""];
		}else{
			//msgBox("Process failed: " + data.resultText);
			ga('send', 'event', $('#sysPageTitle').text() + '-add/edit/delete', '失敗', data.resultText, 1);
			return [false, "Process failed: " + data.resultText, ""];
		}
	}
}	//function checkAjaxResultCode(response, postdata, formid){

//將 jqgrid table 的資料匯出至 Excel
function exportToExcel(gridTable){	//將 jqgrid table 的資料匯出至 Excel
	exportToExcel(gridTable, 'jqgrid');
}
function exportToExcel(gridTable, tableType){	//將 jqgrid table 的資料匯出至 Excel
	event.preventDefault();
	if(beEmpty(tableType)) tableType = "jqgrid";
	if (tableType=='jqgrid'){
		mya = $('#' + gridTable).getDataIDs(); // Get All IDs in current page
		var data = $('#' + gridTable).getRowData(mya[0]); // Get First row to get the title
	}else{	//一般的 <table>
		var data = $('#' + gridTable);
	}
	// labels
	var colNames = new Array();
	var ii = 0;
	var delimeter = "%RRRR%";
	var linebreak = "%ZZZZ%";
	
	if (tableType=='jqgrid'){
		for ( var i in data) {
			colNames[ii++] = i;
		} // capture col names
	}else{	//一般的 <table>
		$('#' + gridTable + ' > thead  > tr > th ').each(function() {
			colNames[ii++] = $(this).text();
			//alert($(this).text());
		});
	}

	var rows = [];	//存放所有資料
	
	var i = 0;

	if (tableType=='jqgrid'){
		mya = $('#' + gridTable).jqGrid('getGridParam','data');	//這樣才能把全部pages的資料抓出來
		//alert(mya.length);
		for (i = 0; i < mya.length; i++) {
			// Each obj represents a row in the table
			var obj = mya[i];
			// row will collect data from obj
			var row = [];
			for (var key in obj) {
				// Don't iterate through prototype stuff
				if (!obj.hasOwnProperty(key)) continue;
				// Collect the data
				//console.log(obj[key]);
				row.push(obj[key]);
			}
			// Push each row to the main collection as csv string
			rows.push(row.join(delimeter));
		}
		// Put the columnNames at the beginning of all the rows
		rows.unshift(colNames.join(delimeter));
	}else{	//一般的 <table>
		$('#' + gridTable + ' > tbody > tr').each(function() {
			var obj = $(this);
			var row = [];
			$('td', obj).each(function() {
				row.push($(this).text());
			});
			rows.push(row.join(delimeter));
		});
		rows.unshift(colNames.join(delimeter));
	}


	if ( typeof(excelexportform) == "undefined"){
		var form = "<form id='excelexportform' name='excelexportform' action='ajaxSysExportExcelFile.jsp' method='post' target='_blank'>";
		form += "<textarea id='exceldata' name='exceldata' rows='4' cols='50' style='display:none;'></textarea>";
		form += "<button type='submit' id='submitexcelexportform' name='submitexcelexportform' style='display:none;'>Submit</button>";
		form += "</form>";
		$('body').append(form);
	}
	$('#exceldata').val(rows.join(linebreak));
	//console.log($('#excelexportform').serialize());
	$('#submitexcelexportform').click();

	return;
	
}	//function exportToExcel(gridTable){	//將 jqgrid table 的資料匯出至 Excel

