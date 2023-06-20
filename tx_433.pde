/*
ver ::cl 20120520
Configuracion basica para modulo transmisor RT 11
Utiliza libreria VirtualWire.h
pin 01 entrada desde Arduino pin digital 2
pin 02 Tierra
pin 07 tierra
pin 08 antena externa
pin 09 tierra
pin 10 5v
*/


#include "VirtualWire/VirtualWire.h"
#include "VirtualWire/VirtualWire.cpp"

uint8_t CRC_5(uint8_t mensaje[8], size_t n);

static uint8_t divisor = 0x25; //0b100101; //polinomio para CRC

uint8_t CRC_5(uint8_t mensaje[8], size_t n) {
  uint8_t crc = 0b0;
  uint8_t bit;

  for (size_t i = 0; i < n; i++) {
    for (int j = 7; j >= 0; j--) {
      crc <<= 1; //despl. a la derecha para recorrer el mensaje
      bit = (mensaje[i] >> j) & 1;
      crc ^= bit;
      
      if(crc & 0x20){ //0b100000 -> bit más significativo
        crc ^= divisor;
      } 
    }
  }
  
  for(int i = 0; i<5; i++){ //Bits de comprobación
    crc <<= 1;
    
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

int acc = 0;
uint8_t paquete[16];
uint8_t origen[2] = {0b0, 0b1010}; //10
uint8_t destino[2] = {0b0, 0b1010}; //10
uint8_t total = 5; // Total de paquetes = 3 (0b11)
uint8_t mensaje[8] = { //01000111 01011111 00110001 00110010 
  0b0, 0b0, 0b0, 0b0,
  0b01000111, 0b0100000, 0b110001, 0b110000 //msg = "G 10"
};
uint8_t CRC[2] = {0b0, 0b0};

void setup(){
  vw_set_ptt_inverted(true);
  vw_setup(2000);
  vw_set_tx_pin(2);    
  Serial.begin(9600);
  Serial.println("configurando envio");
}
void loop(){
  for (int i = 0; i < total; i++){
    
    CRC[1] = CRC_5(mensaje, sizeof(mensaje));//Calculo de CRC = 1001
 	  uint8_t secuencia = (i+1); //Num paquete = i
    //Copia la información al arreglo paquete
    memcpy(paquete, origen, sizeof(origen));
    memcpy(paquete + sizeof(origen), destino, sizeof(destino));
    memcpy(paquete + sizeof(origen) + sizeof(destino), CRC, sizeof(CRC));
    paquete[sizeof(origen) + sizeof(destino) + sizeof(CRC)] = secuencia;
    paquete[sizeof(origen) + sizeof(destino) + sizeof(CRC) + 1] = total;
    memcpy(paquete + sizeof(origen) + sizeof(destino) + sizeof(CRC) + 2, mensaje, sizeof(mensaje));

    vw_send(paquete, sizeof(paquete));
    vw_wait_tx();
    Serial.println("mensaje enviado");
    Serial.print("Paquete ");
    Serial.println(static_cast<int>(secuencia));
    imprimirMensaje(paquete, sizeof(paquete));
    //Serial.println(static_cast<int>(CRC[1]));   
    delay(1000);
  }
}