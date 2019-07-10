var DocumentTitle		= "slimduet Cold Wallet";
var SystemLogoMini		= "SCW";
var SystemLogoLarge		= "slimduet Cold Wallet";

$(document).ready(function() {
	if (beEmpty(getLocalValue("SCWSysAppId")) || beEmpty(getLocalValue("SCWSysCardId"))){	//Couldn't find the paired Card ID
		var thisPageName = "";
		if (document.location.pathname.contains(".html") || document.location.pathname.contains(".jsp")) thisPageName = document.location.pathname.match(/[^\/]+$/)[0];
		if (beEmpty(thisPageName)) thisPageName = "index.html";
		if (thisPageName!="index.html" && thisPageName!="PairCard.html"){
			location.href="index.html";
			return;
		}
	}
	document.title=(DocumentTitle);
	$('.sysCardId').text(getLocalValue("SCWSysCardId"));
	$('.sysAppId').text(getLocalValue("SCWSysAppId"));
	$('.sysWalletId').text(getLocalValue("SCWSysWalletId"));
	$('.sysWalletName').text(getLocalValue("SCWSysWalletName"));
	$('.sysCurrencyName').text(getLocalValue("SCWSysCurrencyName"));
	$('#sysLogoMini').text(SystemLogoMini);
	$('#sysLogoLarge').text(SystemLogoLarge);
	generateMenu();
	generateGoToTopIcon();
});

function generateMenu(){
	var s	= "";

	//以下是使用者的功能選單
	var thisPageName = "";
	if (document.location.pathname.contains(".html") || document.location.pathname.contains(".jsp")) thisPageName = document.location.pathname.match(/[^\/]+$/)[0];
	if (beEmpty(thisPageName)) thisPageName = "index.html";
	s = "";
	s += "<li" + (thisPageName=="CheckBalance.html"?" class='active'":"") + "><a href='CheckBalance.html'><i class='fa fa-balance-scale'></i> Check Balance</a></li>";
	s += "<li" + (thisPageName=="ReceiveMoney.html"?" class='active'":"") + "><a href='ReceiveMoney.html'><i class='fa fa-download'></i> Receive Money</a></li>";
	s += "<li" + (thisPageName=="SendMoney.html"?" class='active'":"") + "><a href='SendMoney.html'><i class='fa fa-upload'></i> Send Money</a></li>";
	s += "<li" + (thisPageName=="TransactionHistory.html"?" class='active'":"") + "><a href='TransactionHistory.html'><i class='fa fa-table'></i> Transaction History</a></li>";
	s += "<li" + (thisPageName=="WalletManagement.html"?" class='active'":"") + "><a href='WalletManagement.html'><i class='fa fa-columns'></i> My Wallet</a></li>";
	s += "<li" + (thisPageName=="SIMActivities.html"?" class='active'":"") + "><a href='SIMActivities.html'><i class='fa fa-mobile-phone'></i> Cold Wallet SIM Activities</a></li>";
	/**
	s += "<li class='treeview" + (thisPageName=="WalletList.html"||thisPageName=="WalletCreate.html"?" active":"") + "'>";
	s += "	<a href='#'>";
	s += "		<i class='fa fa-edit'></i>";
	s += "		<span>Wallet Management</span>";
	s += "		<span class='pull-right-container'>";
	s += "			<i class='fa fa-angle-left pull-right'></i>";
	s += "		</span>";
	s += "	</a>";
	s += "	<ul class='treeview-menu'>";
	s += "		<li" + (thisPageName=="WalletList.html"?" class='active'":"") + "><a href='WalletList.html'><i class='fa fa-circle-o'></i> My Wallet</a></li>";
	s += "		<li" + (thisPageName=="WalletCreate.html"?" class='active'":"") + "><a href='WalletCreate.html'><i class='fa fa-circle-o'></i> Create Wallet</a></li>";
	s += "	</ul>";
	s += "</li>";
	*/
	s += "<li class='treeview" + (thisPageName=="PairCard.html"||thisPageName=="SystemInfo.html"?" active":"") + "'>";
	s += "	<a href='#'>";
	s += "		<i class='fa fa-gear'></i>";
	s += "		<span>Settings</span>";
	s += "		<span class='pull-right-container'>";
	s += "			<i class='fa fa-angle-left pull-right'></i>";
	s += "		</span>";
	s += "	</a>";
	s += "	<ul class='treeview-menu'>";
	s += "		<li" + (thisPageName=="PairCard.html"?" class='active'":"") + "><a href='PairCard.html'><i class='fa fa-circle-o'></i> Pair Cold Wallet SIM</a></li>";
	s += "		<li" + (thisPageName=="SystemInfo.html"?" class='active'":"") + "><a href='SystemInfo.html'><i class='fa fa-circle-o'></i> System Information</a></li>";
	s += "	</ul>";
	s += "</li>";

	
	$('#sysSidebarMenu').append(s);
}	//function generateMenu(){

function generateGoToTopIcon(){
  var slideToTop = $("<div />");
  slideToTop.html('<i class="fa fa-chevron-up"></i>');
  slideToTop.css({
    position: 'fixed',
    bottom: '40px',
    right: '25px',
    width: '40px',
    height: '40px',
    color: '#eee',
    'font-size': '',
    'line-height': '40px',
    'text-align': 'center',
    'background-color': '#222d32',
    cursor: 'pointer',
    'border-radius': '5px',
    'z-index': '99999',
    opacity: '.5',
    'display': 'none'
  });
  slideToTop.on('mouseenter', function () {
    $(this).css('opacity', '1');
  });
  slideToTop.on('mouseout', function () {
    $(this).css('opacity', '.7');
  });
  $('.wrapper').append(slideToTop);
  $(window).scroll(function () {
    if ($(window).scrollTop() >= 150) {
      if (!$(slideToTop).is(':visible')) {
        $(slideToTop).fadeIn(500);
      }
    } else {
      $(slideToTop).fadeOut(500);
    }
  });
  $(slideToTop).click(function () {
    $("html, body").animate({
      scrollTop: 0
    }, 500);
  });
}