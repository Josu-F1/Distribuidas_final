import React from 'react';
import SessionInfo from '../components/SessionInfo';

const Account: React.FC = () => {
  return (
    <div>
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Mi Cuenta</h1>
        <p className="text-gray-500 mt-1">Administra tu información de acceso y configuración del sistema.</p>
      </div>
      
      <div className="flex justify-center w-full">
        <SessionInfo />
      </div>
    </div>
  );
};

export default Account;
