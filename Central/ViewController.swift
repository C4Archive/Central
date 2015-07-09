//
//  ViewController.swift
//  Central
//
//  Created by travis on 2015-07-08.
//  Copyright (c) 2015 C4. All rights reserved.
//

import Cocoa
import CoreBluetooth

class ViewController: NSViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager : CBCentralManager?
    let connection_service_uuid = CBUUID(string: "39BB9101-9800-4C6D-B032-CAC5ABEA1B76")
    let transfer_service_uuid = CBUUID(string: "4268FA37-EADC-4C47-AFF8-15B4569BDE05")
    var connectedPeripherals = [NSUUID : CBPeripheral]()
    var discoveredPeripherals = [NSUUID : CBPeripheral]()
    var currentConnectedPeripheral : CBPeripheral?
    let transfer_characteristic = CBMutableCharacteristic(type: CBUUID(string: "F5815D05-DDDC-4922-BD79-63C6F4538D4D"), properties: .Write | .Read | .Notify, value: nil, permissions: .Readable | .Writeable)

    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: dispatch_get_main_queue())
    }

    //MARK:-
    //MARK: Central Manager
    //MARK: Monitoring Connections
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        if let identifier = peripheral.identifier {
            if connectedPeripherals[identifier] == nil {
                println("connected to \(peripheral)")
                discoveredPeripherals.removeValueForKey(identifier)
                currentConnectedPeripheral = peripheral
                connectedPeripherals[currentConnectedPeripheral!.identifier] = currentConnectedPeripheral
                currentConnectedPeripheral?.delegate = self
                currentConnectedPeripheral?.discoverServices([transfer_service_uuid])
                centralManager?.scanForPeripheralsWithServices([connection_service_uuid], options: nil)
            }
        }
    }

    func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        println("disconnected from \(peripheral)")
        connectedPeripherals.removeValueForKey(peripheral.identifier)
        discoveredPeripherals.removeValueForKey(peripheral.identifier)
        centralManager?.scanForPeripheralsWithServices([connection_service_uuid], options: nil)
    }

    func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        println("failed to connect to \(peripheral) with error \(error)")
    }

    //MARK: Discovering and Retrieving
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        if let identifier = peripheral.identifier {
            if let p = discoveredPeripherals[identifier] {
                return
            }
            if let p = connectedPeripherals[identifier]  {
                return
            }
            println("discovered \(peripheral)")
            discoveredPeripherals[identifier] = peripheral

            if let services = discoveredPeripherals[identifier]?.services {
                if let service = services[0] as? CBService {
                    discoveredPeripherals[identifier]?.discoverCharacteristics([transfer_characteristic], forService: service)
                }
            } else {
                discoveredPeripherals[identifier]?.discoverServices([transfer_service_uuid])
            }

            discoveredPeripherals[identifier]?.delegate = self
            centralManager?.connectPeripheral(discoveredPeripherals[identifier], options: nil)
        }
    }

    func centralManager(central: CBCentralManager!, didRetrieveConnectedPeripherals peripherals: [AnyObject]!) {
        println("retrieved connected peripherals \(peripherals)")
    }

    func centralManager(central: CBCentralManager!, didRetrievePeripherals peripherals: [AnyObject]!) {
        println("retrieved peripherals \(peripherals)")
    }

    //MARK: Central Manager State
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        println("didUpdateState")
        centralManager?.scanForPeripheralsWithServices([connection_service_uuid], options: nil)
    }

    func centralManager(central: CBCentralManager!, willRestoreState dict: [NSObject : AnyObject]!) {
        println("willRestoreState \(dict)")
    }

    //MARK:-
    //MARK: Peripheral Delegate
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        println("discovered services: \(peripheral.services)")
        if let p = connectedPeripherals[peripheral.identifier] {
            for s in p.services {
                if let service = s as? CBService {
                    if service.UUID == transfer_service_uuid {
                        peripheral.discoverCharacteristics([transfer_characteristic.UUID], forService: service)
                    }
                }
            }
        }
    }

    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        println("discovered characteristics for \(service)")
        for c in service.characteristics {
            if let characteristic = c as? CBCharacteristic {
                if characteristic.UUID == transfer_characteristic.UUID {
                    peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                    println("notify")
                }
            }
        }
    }

    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        println("updated value for \(characteristic)")
    }

    func peripheral(peripheral: CBPeripheral!, didWriteValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        println("wrote value for \(characteristic)")
    }

    func peripheral(peripheral: CBPeripheral!, didReadRSSI RSSI: NSNumber!, error: NSError!) {
        println("read RSSI \(RSSI)")
    }
}

