class TextProgressBar{
  int max;
  int min;
  int curr;
  int w; // in characters
  String title;
  
  TextProgressBar(String title, int max){
    min = 0;
    this.max = max;
    curr = min;
    w = 80;
    this.title = title;
  }
  
  void setMin(int min){
    this.min = min;
  }
  
  void setWidth(int w){
    this.w = w;
  }
  
  void increment(){
    curr++;
    print(title);
    for(int i = 0; i < progressInChars()-1; i++){
      print("=");
    }
    print(">");
    for(int i = 0; i < (w - progressInChars()); i++){
      print(" ");
    }
    println(curr + "/" +max);
  }
  
  float progress(){
    return (float)curr/(max-1);
  }
  
  int progressInChars(){
    return (int)(progress()*w);
  }
}
