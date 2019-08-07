<%@ page language="java" pageEncoding="utf-8" contentType="text/html;charset=utf-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

<%@page import="java.net.InetAddress" %>
<%@page import="org.json.simple.JSONObject" %>
<%@page import="java.util.*" %>

<%@include file="00_constants.jsp"%>
<%@include file="00_utility.jsp"%>

<%
/***************輸入範例********************************************************
https://cms.gslssd.com/wallet/bPair.jsp?cardid=1234567890123456&paircode=520333
*******************************************************************************/

/***************輸出範例********************************************************
成功
DDDDDDFD

失敗
DDDDDD0000596a6176612e73716c2e4261746368557064617465457863657074696f6e3a2044617461207472756e636174696f6e3a204461746120746f6f206c6f6e6720666f7220636f6c756d6e202749434349442720617420726f772031
*******************************************************************************/
%>

<%
request.setCharacterEncoding("utf-8");
response.setContentType("text/html;charset=utf-8");
response.setHeader("Pragma","no-cache"); 
response.setHeader("Cache-Control","no-cache"); 
response.setDateHeader("Expires", 0); 

out.clear();	//注意，一定要有out.clear();，要不然client端無法解析XML，會認為XML格式有問題

JSONObject	obj=new JSONObject();

String	sResponse	= "";

/*********************開始做事吧*********************/

String cardId		= nullToString(request.getParameter("cardId"), "");
String hashIndex	= nullToString(request.getParameter("hashIndex"), "");
String signature	= nullToString(request.getParameter("signature"), "");


if (beEmpty(cardId) || beEmpty(hashIndex) || (!hashIndex.equals("0") && beEmpty(signature))){
	writeLog("debug", "BIP get data to be signed parameter not found for Card_Id= " + cardId + ", hashIndex= " + hashIndex + ", signature= " + signature);
	obj.put("resultCode", gcResultCodeParametersNotEnough);
	obj.put("resultText", gcResultTextParametersNotEnough);
	out.print(obj);
	out.flush();
	return;
}else{
	writeLog("debug", "BIP get data to be signed for Card_Id= " + cardId + ", hashIndex= " + hashIndex + ", signature= " + signature);
}

Hashtable	ht					= new Hashtable();
String		sResultCode			= gcResultCodeSuccess;
String		sResultText			= gcResultTextSuccess;
String		s[][]				= null;
String		sSQL				= "";
List<String> sSQLList			= new ArrayList<String>();
String		sDate				= getDateTimeNow(gcDateFormatSlashYMDTime);
String		sUser				= "System";

String		ss					= "";
int			i					= 0;
int			j					= 0;
int			k					= 0;
int			l					= 0;

String	walletId				= "";
String	path					= "";
String	currencyId				= "";
String	transactionId			= "";
String	hashToBeSigned			= "";
String	sApdu					= "";
int		iSignatureCount			= 1;

//hashIndex=0 -> 找第一筆hash送給卡片
//hashIndex>0 -> 將signature寫入DB，看一下一共有幾筆hash，然後決定要送下一筆hash，還是將交易送到鏈上

sSQL = "SELECT B.Wallet_Id, B.Currency_Id, B.Transaction_Id, B.Signature_Count";
sSQL += " FROM cwallet_bip_job_queue A, cwallet_transaction B";
sSQL += " WHERE A.Card_Id='" + cardId + "'";
sSQL += " AND A.CMD='" + "50" + "'";
sSQL += " AND A.Status='" + "Sync" + "'";
sSQL += " AND A.Transaction_Id=B.Transaction_Id";
sSQL += " ORDER BY A.id desc";
sSQL += " LIMIT 1";

ht = getDBData(sSQL, gcDataSourceNameCMSIOT);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();
if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	s = (String[][])ht.get("Data");
	walletId = s[0][0];
	currencyId = s[0][1];
	transactionId = s[0][2];
	if (notEmpty(s[0][3])) iSignatureCount = Integer.parseInt(s[0][3]);
	
	if (!hashIndex.equals("0") && notEmpty(signature)){	//如果有傳入signature，就先更新cwallet_transaction_hash
		sSQL = "UPDATE cwallet_transaction_hash";
		sSQL += " SET Signed_Hex='" + signature + "'";
		sSQL += " ,Status='Sync'";
		sSQL += " ,Update_User='" + sUser + "'";
		sSQL += " ,Update_Date='" + sDate + "'";
		sSQL += " WHERE Transaction_Id='" + transactionId + "'";
		sSQL += " AND Hash_Index=" + hashIndex;
		sSQLList.add(sSQL);
		ht = updateDBData(sSQLList, gcDataSourceNameCMSIOT, false);
		sResultCode = ht.get("ResultCode").toString();
		sResultText = ht.get("ResultText").toString();
		if (!sResultCode.equals(gcResultCodeSuccess)){
			obj.put("resultCode", sResultCode);
			obj.put("resultText", sResultText);
			out.print(obj);
			out.flush();
			return;
		}
	}	//if (!hashIndex.equals("0") && notEmpty(signature)){	//如果有傳入signature，就先更新cwallet_transaction_hash

	//再來找看看有沒有尚未簽名的，有的話就回給卡片，沒有的話就把簽名資料送到鏈上去	
	sSQL = "SELECT Hash_Index, Hash_To_Be_Signed FROM cwallet_transaction_hash";
	sSQL += " WHERE Transaction_Id='" + transactionId + "'";
	if (hashIndex.equals("0")){
		sSQL += " AND Hash_Index=1";	//找第一筆
	}else{
		sSQL += " AND (Signed_Hex IS NULL OR Status='Init')";
	}
	sSQL += " ORDER BY Hash_Index";
	sSQL += " LIMIT 1";
	ht = getDBData(sSQL, gcDataSourceNameCMSIOT);
	
	sResultCode = ht.get("ResultCode").toString();
	sResultText = ht.get("ResultText").toString();
	if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
		s = (String[][])ht.get("Data");
		sApdu = composeApdu(walletId, currencyId, (hashIndex.equals("0")?"0":s[0][0]), iSignatureCount, s[0][1]);
		obj.put("apdu", sApdu);
	}else if (sResultCode.equals(gcResultCodeNoDataFound)){	//沒資料
		if (hashIndex.equals("0")){	//此時不可能沒資料，至少要有一筆才對
			writeLog("error", "BIP unable to find first hash for signing, sSQL= " + sSQL + ", sResultCode= " + sResultCode + ", sResultText= " + sResultText);
			obj.put("resultCode", sResultCode);
			obj.put("resultText", sResultText);
			out.print(obj);
			out.flush();
			return;
		}	//if (hashIndex.equals("0")){	//此時不可能沒資料，至少要有一筆才對
		//所有的hash都有值了，送到鏈上去吧
		writeLog("info", "Going to send raw transaction to blockchain, Transaction_Id= " + transactionId);
		String	myURL		= "http://ip-172-31-31-149.ap-southeast-1.compute.internal:8080/wallet/";	//目前程式所處的URL路徑，不含檔名
		
		if (request.getServerPort()==8088){	//Sunny notebook
			myURL = request.getScheme()+"://"+request.getServerName()+":"+request.getServerPort()+request.getContextPath()+"/";	//目前程式所處的URL路徑，不含檔名
		}else{
			myURL = "http://ip-172-31-31-149.ap-southeast-1.compute.internal:8080/wallet/";	//目前程式所處的URL路徑，不含檔名
		}
		
		out.print(doPushRawTransaction(myURL, currencyId, transactionId));
		out.flush();
		return;
	}else{
		writeLog("error", "BIP get hash to be signed failed, sSQL= " + sSQL + ", sResultCode= " + sResultCode + ", sResultText= " + sResultText);
		obj.put("resultCode", sResultCode);
		obj.put("resultText", sResultText);
		out.print(obj);
		out.flush();
		return;
	}	//if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	
}else{
	writeLog("error", "BIP get transaction to be signed failed, sSQL= " + sSQL + ",  sResultCode= " + sResultCode + ", sResultText= " + sResultText);
	obj.put("resultCode", sResultCode);
	obj.put("resultText", sResultText);
	out.print(obj);
	out.flush();
	return;
}	//if (sResultCode.equals(gcResultCodeSuccess)){	//有資料


obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);
writeLog("debug", "Response message= " + obj.toString());
out.print(obj);
out.flush();
%>

<%!
	public String composeApdu(String walletId, String currencyId, String hashIndex, int iSignatureCount, String hashToBeSigned){
		String sApdu = "00";	//default = BTC
		if (currencyId.equals("BTCTEST")) sApdu = "01";
		if (currencyId.equals("ETH") || currencyId.equals("ETHTEST")) sApdu = "3C";
		sApdu = "8000002C" + "800000" + sApdu + "80000000" + "00000000" + "00000000";	//Path
		String nextAction = "50";
		//if ((hashIndex.equals("0") && iSignatureCount==1) || (!hashIndex.equals("0") && Integer.parseInt(hashIndex)==iSignatureCount)) nextAction = "51";
		nextAction = "51";
		sApdu = "AABBDD" + (hashIndex.equals("0")?"50":"51") + nextAction + "00" + "01" + MakesUpZero(Integer.toHexString(Integer.parseInt(hashIndex)), 2) + MakesUpZero(Integer.toHexString(iSignatureCount), 2) + MakesUpZero(Integer.toHexString((sApdu+hashToBeSigned).length()/2+1), 2) + MakesUpZero(walletId, 2) + sApdu + hashToBeSigned;
		return sApdu;
	}
	
	public String doPushRawTransaction(String myURL, String currencyId, String transactionId){
		String sJsp = "";
		String sData = "";
		String sResponse = "";

		if (currencyId.equals("BTC") || currencyId.equals("BTCTEST")){
			sJsp = "bPushSignedTransaction.jsp";
			sData = "transactionId=" + transactionId;
		}else{
			sJsp = "bPushSignedTransactionETH.jsp";
			sData = "transactionId=" + transactionId;
		}

		writeLog("debug", "Connect to transaction push process: " + myURL + sJsp);
		try{
			URL u;
			u = new URL(myURL + sJsp);
			HttpURLConnection uc = (HttpURLConnection)u.openConnection();
			//uc.setRequestProperty ("Content-Type", "application/json");
			uc.setRequestProperty("charset", "utf-8");
			uc.setRequestMethod("POST");
			uc.setRequestProperty("Content-Type", "application/x-www-form-urlencoded"); 
			uc.setDoOutput(true);
			uc.setDoInput(true);
		
			byte[] postData = sData.getBytes("UTF-8");	//避免中文亂碼問題
			OutputStream os = uc.getOutputStream();
			os.write(postData);
			os.close();
		
			InputStream in = uc.getInputStream();
			BufferedReader r = new BufferedReader(new InputStreamReader(in));
			StringBuffer buf = new StringBuffer();
			String line;
			while ((line = r.readLine())!=null) {
				buf.append(line);
			}
			in.close();
			sResponse = buf.toString();	//取得Line回應值
		}catch (IOException e){ 
			sResponse = e.toString();
			writeLog("error", "Exception when push raw transaction: " + e.toString());
			sResponse = "AABBDDA20000010101" + Integer.toHexString(string2Hex(sResponse, "UTF8").length()) + "04" + string2Hex(sResponse, "UTF8");
			writeLog("error", "Response= " + sResponse);
			return sResponse;
		}
		return sResponse;
	}
%>