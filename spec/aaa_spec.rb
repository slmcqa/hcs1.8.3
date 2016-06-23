## To change this license header, choose License Headers in Project Properties.
## To change this template file, choose Tools | Templates
## and open the template in the editor.
#
#require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
#
#describe Aaa do
#  before(:each) do
#    @aaa = Aaa.new
#  end
#
#  it "should desc" do
#var err ='';
#var AdminLock = ''
#var useN = $('#username').val();
#if($('#status').length > 0){
#var errMsg = $('#status').text();
#if(errMsg.match(/User account is locked/g) =='User account is locked'){
#$('#status').html('Account is Locked. Please contact IT System Administrator to unlock account, or answer the question.')
#}else if (errMsg.match(/User account has expired/g)=='User account has expired'){
#$('#status').html('Account is expired. Please contact IT System Administrator.')
#}else if (errMsg.match(/User is disabled/g)=='User is disabled'){
#$('#status').html('Account is disabled. Please contact IT System Administrator.')
#}
#if($('#status').text().match(/lock/g)=='lock' || err =='locked'){
#if(AdminLock =='y'){
#$('#status').empty()
#$('#status').html('Account has been locked by an administrator. Please contact IT System Administrator.')
#}else{
#getSecQ();
#$('#submit').html('Unlock')
#$('#btnReset').hide();
#$('input[name="username"]').val(useN)
#$('div[name="dvFRM"]').hide();
#$('input[name="password"]').val(' ')
#$('#_eventId').val('unlock');
#$('#divSecQuestion').show();
#}
#}
#}
#if(err !=''){
#$('#status').html('');
#if(err=='locked'){
#if(AdminLock =='y'){
#$('#status').empty()
#$('#status').html('Account has been locked by an administrator. Please contact IT System Administrator.')
#}
#}
#}
#function checkBtn(){
#if($('#submit').html()=='Unlock'){
#var retVal = JSON.parse(validateSecQ());
#// alert(retVal.valid)
#return retVal.valid;
#}else{
#return true;
#}
#}
#function resetPassword(){
#$('input[name="username"]').val(' ');
#$('input[name="password"]').val(' ');
#$('input[name="password"]').hide();
#$('input[name="password"]').attr('type',"text");
#$('#_eventId').val('reset');
#$('#rsetIT').val('y');
#$('#submit').click();
#}
#window.setInterval(
#function() {
#if ($('#errDiv').children().length > 0) {
#$('#errDiv').show();
#}
#}, 500);
#var secQList;
#function getSecQ(){
#url = '/admin/AdminController';
#var param = {
#"operation" : 'secQ',
#"uname" : useN,
#"opt" : '1',
#"isAjax" : 'y'
#};
#$.ajax({
#url : url,
#type : 'POST',
#dataType : 'json',
#data : param,
#success : function(data) {
#if(data.USEQL.length > 0){
#secQList= data.USEQL;
#var idx =randomIntFromInterval(0,(data.USEQL.length -1))
#$('#txtQuestion').val(data.USEQL[idx].QUESTION)
#$('#txtQuestionId').val(data.USEQL[idx].ID)
#$('div[name="dvFRM"]').hide();
#$('#divSecQuestion').show();
#}else{
#$('#status').append("<div>No security question was retrieved for the user. Can't proceed with transaction.</div>");
#$('#errDiv').slideDown();
#$('#cancel').show();
#$('#submit').hide();
#$('#divSecQuestion').hide();
#}
#},
#error:function(){
#//something
#}
#});
#}
#function validateSecQ(){
#$('#status').empty();
#$('#errDiv').hide();
#url = '/admin/AdminController';
#var param = {
#"operation" : 'secQ',
#"uname" : useN,
#"qid" : $('#txtQuestionId').val(),
#"qAns" : $('#txtQAns').val(),
#"opt" : '2',
#"isAjax" : 'y'
#};
#return $.ajax({
#url : url,
#type : 'POST',
#dataType : 'json',
#async: false,
#data : param,
#success : function(data) {
#var isValid = data.valid;
#if(!isValid){
#$('#status').append("<div>Security validation failed.</div>");
#$('#errDiv').slideDown();
#var idx =randomIntFromInterval(0,secQList.length)
#$('#txtQuestion').val(secQList[idx].QUESTION)
#$('#txtQuestionId').val(secQList[idx].ID)
#$('#txtQAns').val('')
#// $('div[name="dvFRM"]').hide();
#// $('#divSecQuestion').show();
#}else{
#$('#unlockIT').val('Y')
#}
#},
#error:function(){
#//something
#}
#}).responseText;
#}
#function randomIntFromInterval(min,max)
#{
#return Math.floor(Math.random()*(max-min+1)+min);
#}
#var serv = '';
#if (serv!=''){
#window.location.replace('/');
#}
#
#  end
#end
#
