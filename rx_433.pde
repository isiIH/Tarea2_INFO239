/*
ver ::cl 20120520
Configuracion basica para modulo receptor  RR 10
Utiliza libreria VirtualWire.h
pin 01 5v
pin 02 Tierra
pin 03 antena externa
pin 07 tierra
pin 10 5v
pin 11 tierra
pin 12 5v
pin 14 Arduino pin digital 2
pin 15 5v
*/

#include "VirtualWire/VirtualWire.h"
#include "VirtualWire/VirtualWire.cpp"

uint8_t CRC_5(uint8_t mensaje[8], size_t n, uint8_t verif);

static uint8_t divisor = 0x25; //0b100101; //polinomio para CRC

uint8_t CRC_5(uint8_t mensaje[8], size_t n, uint8_t verif) {
  uint8_t crc = 0b0;
  uint8_t bit;

  for (size_t i = 0; i < n; i++) {
    for (int j = 7; j >= 0; --j) {
      crc <<= 1; //despl. a la derecha para recorrer el mensaje
      bit = (mensaje[i] >> j) & 1;
      crc ^= bit;
      
      if(crc & 0x20){ //0b100000 -> bit más significativo
        crc ^= divisor;
      } 
    }
  }
  
  for(int i=4; i>=0; --i){ // Remainder calculado por el transmisor
    crc <<= 1;
    bit = (verif >> i) & 1;
    crc ^= bit;
    
    if(crc & 0x20){
      crc ^= divisor;
    } 
  }

  return crc;
}

void imprimirBits(uint8_t valor) {
  for (int i = 7; i >= 0; --i) {
    Serial.print((valor >> i) & 1);
  }
}

void imprimirMensaje(uint8_t mensaje[], int longitud) {
  for (int i = 0; i < longitud; ++i) {
    imprimirBits(mensaje[i]);
    Serial.println();
  }
}

void setup(){
  Serial.begin(9600);
    
  vw_set_ptt_inverted(true); 
  vw_setup(2000);
  vw_set_rx_pin(2);
  vw_rx_start();
  Serial.println("Esperando el mensaje...");
}

int c = 0;

void loop(){
  uint8_t buf[VW_MAX_MESSAGE_LEN];
  uint8_t buflen = VW_MAX_MESSAGE_LEN;

  if (vw_get_message(buf, &buflen)){
    uint8_t origen[2] = {buf[0], buf[1]};
    uint8_t destino[2] = {buf[2], buf[3]};
    digitalWrite(13, true);

    if(destino[1] == 0b1100 || destino[1] == 0b0){ //Si es para nuestro grupo = 12 o 00

      Serial.print("Origen = G");
      Serial.print(int(origen[1]));
      Serial.print(", ");

      uint8_t msg[8] = {buf[8],buf[9],buf[10],buf[11],buf[12],buf[13],buf[14],buf[15]};
      uint8_t crc = CRC_5(msg, sizeof(msg), buf[5]);
      
      if(crc != 0b0){
        Serial.println("Error en el envio de datos");
        c++;
        Serial.print("Número de errores = ");
        Serial.println(c);
      } else {
        char mensaje[8] = "xd";
        uint8_t sec = buf[6];
        uint8_t total = buf[7];

        int cont = 0;
        for(int i=0; i<sizeof(msg); i++){
          if(msg[i] != 0b0){ 
            mensaje[cont] = static_cast<char>(msg[i]);
            cont++;
          }
        }

        //imprimirMensaje(mensaje, sizeof(mensaje));

        Serial.print("Paquete ");
        Serial.print(sec);
        Serial.print(" = ");
        
        for(int i=0; i<cont; i++){
          Serial.print(mensaje[i]);
        }
        Serial.println();
      }
    }
    digitalWrite(13, false);
  }
}
