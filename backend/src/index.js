const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
const http = require('http');
const { Server } = require('socket.io');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

const port = process.env.PORT || 5000;

// Middleware
app.use(helmet({
  contentSecurityPolicy: false, // Turn off CSP for easy Firebase CDN scripts injection
}));
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());
app.use(express.static(path.join(__dirname, '../public')));

// Panel Page Handlers
app.get('/doctor', (req, res) => {
  res.sendFile(path.join(__dirname, '../public/doctor.html'));
});

app.get('/admin', (req, res) => {
  res.sendFile(path.join(__dirname, '../public/admin.html'));
});

// Routes
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, '../public/index.html'));
});

// Health check route
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK' });
});

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// API ROUTES FOR PERFECT SYNC
app.get('/api/sync', async (req, res) => {
  try {
    const clinics = await prisma.clinic.findMany();
    const doctors = await prisma.doctor.findMany();
    const appointments = await prisma.appointment.findMany();
    const reports = await prisma.report.findMany();
    res.json({ clinics, doctors, appointments, reports });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/appointments', async (req, res) => {
  try {
    const appt = await prisma.appointment.create({ data: req.body });
    io.emit('db_update', { type: 'appointment_created', data: appt });
    res.json(appt);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.put('/api/appointments/:id', async (req, res) => {
  try {
    const appt = await prisma.appointment.update({
      where: { id: req.params.id },
      data: req.body
    });
    io.emit('db_update', { type: 'appointment_updated', data: appt });
    res.json(appt);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/reports', async (req, res) => {
  try {
    const report = await prisma.report.create({ data: req.body });
    io.emit('db_update', { type: 'report_created', data: report });
    res.json(report);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// PRESCRIPTIONS & ACTIVITY LOGS
app.post('/api/prescriptions', async (req, res) => {
  try {
    const { appointmentId, patientId, doctorName, diagnosis, medicines, notes } = req.body;
    
    const prescription = await prisma.prescription.create({
      data: {
        appointmentId,
        patientId,
        doctorName,
        diagnosis,
        medicines,
        notes
      }
    });

    await prisma.activityLog.create({
      data: {
        role: 'DOCTOR',
        action: 'ISSUED_PRESCRIPTION',
        details: `${doctorName} issued prescription for Appt: ${appointmentId}`
      }
    });

    // Update appointment status to COMPLETED
    const appt = await prisma.appointment.update({
      where: { id: appointmentId },
      data: { status: 'COMPLETED' }
    });

    io.emit('db_update', { type: 'prescription_created', data: prescription });
    io.emit('db_update', { type: 'appointment_updated', data: appt });

    res.json(prescription);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/activity', async (req, res) => {
  try {
    const logs = await prisma.activityLog.findMany({
      orderBy: { createdAt: 'desc' },
      take: 50
    });
    res.json(logs);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// AUTHENTICATION AND PERSISTENCE
app.post('/api/auth/verify', async (req, res) => {
  try {
    const { phone, role, authKey } = req.body;
    
    // Auth Key Check for Staff
    if ((role === 'doctor' || role === 'admin') && authKey !== 'aarogya123') {
      return res.status(401).json({ error: 'Invalid Auth Key.' });
    }

    const user = await prisma.user.findUnique({
      where: { phone },
      include: { patient: true, doctor: true }
    });

    if (user) {
      return res.json({ isNew: false, user });
    } else {
      return res.json({ isNew: true });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/users/profile', async (req, res) => {
  try {
    const { phone, name, role, age, gender, address, medicalHistory } = req.body;
    
    const user = await prisma.user.create({
      data: {
        phone,
        name,
        role: role.toUpperCase()
      }
    });

    if (role === 'patient') {
      await prisma.patient.create({
        data: {
          userId: user.id,
          age: parseInt(age) || 0,
          gender: gender || 'Other',
          address: address || '',
          medicalHistory: medicalHistory || ''
        }
      });
    } else if (role === 'doctor') {
      await prisma.doctor.create({
        data: {
          userId: user.id,
          specialization: 'General'
        }
      });
    }

    const fullUser = await prisma.user.findUnique({
      where: { id: user.id },
      include: { patient: true, doctor: true }
    });

    res.json(fullUser);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/seed', async (req, res) => {
  try {
    await prisma.clinic.deleteMany();
    await prisma.doctor.deleteMany();
    await prisma.appointment.deleteMany();
    await prisma.report.deleteMany();

    const clinic = await prisma.clinic.create({
      data: {
        name: 'Primary Care Unit A',
        vehicleNumber: 'DL-01-A-1234',
        latitude: 28.6139,
        longitude: 77.2090,
        address: 'Sector 62',
        currentLocation: 'Noida Sector 62 Main Crossing, UP',
        services: 'General Checkup, Pediatrics',
        status: 'ACTIVE'
      }
    });

    // Create a dummy user for the doctor
    let docUser = await prisma.user.findUnique({ where: { phone: '+919999999991' } });
    if (!docUser) {
      docUser = await prisma.user.create({
        data: { name: 'Dr. Aarav Sharma', phone: '+919999999991', role: 'DOCTOR' }
      });
    }

    const doctor = await prisma.doctor.create({
      data: {
        userId: docUser.id,
        specialization: 'General Physician',
        clinicId: clinic.id,
        isAvailable: true
      }
    });
    
    io.emit('db_update', { type: 'seed_complete' });
    res.json({ message: 'Seeded successfully', clinic, doctor });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Socket.io event pipeline
io.on('connection', (socket) => {
  console.log('A client connected to real-time sync stream:', socket.id);

  socket.on('gps_update', (data) => {
    console.log('Live GPS position update broadcast:', data);
    io.emit('gps_position', data);
  });

  socket.on('disconnect', () => {
    console.log('Client disconnected from stream:', socket.id);
  });
});

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).send('Something broke!');
});

server.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
