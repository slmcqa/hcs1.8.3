# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Password_bruteforce do
  before(:each) do
    @password_bruteforce = Password_bruteforce.new
  end

  it "Bruteforce Script" do
          #<!DOCTYPE html>
          #<html>
          #<head>
          #<meta charset="utf-8">
          #<title>Bruteforce!</title>
          #</head>
          #<body>
          #<script>
          #var password = '89p8zk',
          #passwordLength = 4,
          #alphabetLength = 36,
          #numberOfTries = 30000,
          #printAfter = 1000,
          #startFrom = 500000000;
          #count = Math.pow(passwordLength, alphabetLength);
          #document.write('<strong>Number of required tries in worst case:</strong> ' + count + '<br>');
          #document.write('<strong>Print every</strong> ' + printAfter + 'th try:' + '<br><br>');
          #var thing = [];
          #for (i = startFrom; i < (numberOfTries+startFrom); i++){
          #if (i % printAfter == 0){
          #thing.push("" + i.toString(alphabetLength) + " ");
          #}
          #if (password == i.toString(alphabetLength)){
          #alert('Found password on ' + i + 'th try! Here it is: ' + i.toString(alphabetLength));
          #}
          #}
          #document.write(thing.join(''));
          #document.write('<br><br>Last is: a' + i.toString(alphabetLength));
          #</script>
          #</body>
          #</html>
  end
end

